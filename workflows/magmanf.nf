/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap        } from 'plugin/nf-schema'
include { paramsSummaryMultiqc    } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML  } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText  } from '../subworkflows/local/utils_nfcore_tbanalyzer_pipeline'

// ── Validation ────────────────────────────────────────────────────────────────
include { SAMPLESHEET_VALIDATION   } from '../modules/local/magma/utils/samplesheet_validation'
include { VALIDATE_FASTQS_WF       } from '../subworkflows/local/magma/validate_fastqs_wf'

// ── Mapping ────────────────────────────────────────────────────────────────────
include { MAP_WF                   } from '../subworkflows/local/magma/map_wf'

// ── Per-sample calling + minor variants ────────────────────────────────────────
include { CALL_WF                       } from '../subworkflows/local/magma/call_wf'
include { MINOR_VARIANTS_ANALYSIS_WF    } from '../subworkflows/local/magma/minor_variants_analysis_wf'
include { UTILS_MERGE_COHORT_STATS      } from '../modules/local/magma/utils/merge_cohort_stats'

// ── QC (FastQC, NTMprofiler, TBprofiler fastq, SpoTyping) ─────────────────────
include { QUALITY_CHECK_WF         } from '../subworkflows/local/magma/quality_check_wf'

// ── Structural variants (DELLY) ────────────────────────────────────────────────
include { STRUCTURAL_VARIANTS_ANALYSIS_WF } from '../subworkflows/local/magma/structural_variants_analysis_wf'

// ── Cohort joint-genotyping + phylogeny + clustering ──────────────────────────
include { MERGE_WF                } from '../subworkflows/local/magma/merge_wf'

// ── Final reports (resistance summaries + MultiQC) ────────────────────────────
include { REPORTS_WF              } from '../subworkflows/local/magma/reports_wf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow MAGMA {

    take:
    ch_samplesheet             // channel: samplesheet read in from --input (nf-core interface)
    multiqc_config             //   param: path to multiqc_config or null
    multiqc_logo               //   param: path to multiqc_logo or null
    multiqc_methods_description //  param: path to methods_description or null
    outdir                     //   param: output directory

    main:

    def ch_versions = channel.empty()

    // =========================================================================
    // SAMPLESHEET VALIDATION + FASTQ VALIDATION
    // NOTE: MAGMA uses its own CSV format (study, sample, library, …, r1, r2).
    //       We run SAMPLESHEET_VALIDATION directly on params.magma_input_samplesheet
    //       rather than relying on the nf-schema-parsed ch_samplesheet, which
    //       expects a different schema.
    // =========================================================================

    SAMPLESHEET_VALIDATION(file(params.magma_input_samplesheet ?: params.input, checkIfExists: true))

    VALIDATE_FASTQS_WF(
        SAMPLESHEET_VALIDATION.out.validated_samplesheet,
        SAMPLESHEET_VALIDATION.out.status
    )

    def approved_fastqs_ch = VALIDATE_FASTQS_WF.out.approved_fastqs_ch

    // =========================================================================
    // QUALITY CHECK (FastQC, NTMprofiler, TBprofiler FASTQ, SpoTyping)
    // =========================================================================

    QUALITY_CHECK_WF(approved_fastqs_ch)

    // =========================================================================
    // EARLY EXIT: only_validate_fastqs mode
    // =========================================================================

    if (!params.magma_only_validate_fastqs) {

        // =====================================================================
        // MAPPING — MAP_WF (BWA-MEM)
        // =====================================================================

        MAP_WF(approved_fastqs_ch)

        // =====================================================================
        // CALL_WF — per-sample variant calling + QC stats
        // =====================================================================

        CALL_WF(MAP_WF.out.sorted_reads_ch)

        // gvcf channel reconstructed from CALL_WF's separate tbi+vcf emits.
        // Match torch-magma's gvcf_ch shape: collected stream of [meta, tbi, vcf].
        def gvcf_ch = CALL_WF.out.gvcf_tbi_ch.join(CALL_WF.out.gvcf_vcf_ch).collect()

        def lofreq_vcf_tuple_ch = CALL_WF.out.reformatted_lofreq_vcfs_tuple_ch

        // =====================================================================
        // MINOR VARIANTS ANALYSIS (LoFreq cohort merge + TBprofiler)
        // =====================================================================

        MINOR_VARIANTS_ANALYSIS_WF(lofreq_vcf_tuple_ch, outdir)

        UTILS_MERGE_COHORT_STATS(
            MINOR_VARIANTS_ANALYSIS_WF.out.approved_samples_ch,
            MINOR_VARIANTS_ANALYSIS_WF.out.rejected_samples_ch,
            CALL_WF.out.cohort_stats_tsv
        )

        // Parse merged cohort stats to identify all samples and approved samples
        all_samples_ch = UTILS_MERGE_COHORT_STATS.out.merged_cohort_stats_ch
            .splitCsv(header: false, skip: 1, sep: '\t')
            .map { row -> [ row.first() ] }

        approved_samples_ch = UTILS_MERGE_COHORT_STATS.out.merged_cohort_stats_ch
            .splitCsv(header: false, skip: 1, sep: '\t')
            .map { row -> [ row.first(), row.last().toInteger() ] }
            .filter { it[1] == 1 }
            .map { [ it[0] ] }

        // =====================================================================
        // STRUCTURAL VARIANTS ANALYSIS (DELLY)
        // =====================================================================

        STRUCTURAL_VARIANTS_ANALYSIS_WF(approved_fastqs_ch, all_samples_ch, outdir)

        // =====================================================================
        // MERGE_WF — cohort joint-genotyping + phylogeny + clustering
        // =====================================================================

        if (!params.magma_skip_merge_analysis) {

            MERGE_WF(
                CALL_WF.out.gvcf_tbi_ch,
                CALL_WF.out.gvcf_vcf_ch,
                lofreq_vcf_tuple_ch,
                approved_samples_ch
            )

            // =====================================================================
            // REPORTS_WF — resistance summaries + MultiQC
            // =====================================================================

            REPORTS_WF(
                QUALITY_CHECK_WF.out.reports_fastqc_ch,
                UTILS_MERGE_COHORT_STATS.out.merged_cohort_stats_ch,
                MERGE_WF.out.major_variants_results_ch,
                MINOR_VARIANTS_ANALYSIS_WF.out.minor_variants_results_ch,
                STRUCTURAL_VARIANTS_ANALYSIS_WF.out.structural_variants_results_ch,
                MERGE_WF.out.snp_dists_ch,
                multiqc_config
            )

        } // end !skip_merge_analysis
    } // end !only_validate_fastqs

    // =========================================================================
    // Collate and save software versions (published to pipeline_info)
    // =========================================================================

    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by: 0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name:  'magma_software_mqc_versions.yml',
            sort: true,
            newLine: true
        )

    emit:
    // The MULTIQC report channel for PIPELINE_COMPLETION.  We guard against the
    // skip_merge_analysis / only_validate_fastqs paths where REPORTS_WF never
    // runs by emitting an empty channel in that case.
    multiqc_report = (params.magma_only_validate_fastqs || params.magma_skip_merge_analysis)
        ? channel.empty()
        : REPORTS_WF.out.multiqc_report
    versions       = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

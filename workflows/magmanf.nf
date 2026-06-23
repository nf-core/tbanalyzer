/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                  } from '../modules/local/magma/nf-core/fastqc/main'
include { MULTIQC                 } from '../modules/local/magma/multiqc/main'
include { paramsSummaryMap        } from 'plugin/nf-schema'
include { paramsSummaryMultiqc    } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML  } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText  } from '../subworkflows/local/utils_nfcore_tbanalyzer_pipeline'

// ── Validation ────────────────────────────────────────────────────────────────
include { SAMPLESHEET_VALIDATION   } from '../modules/local/magma/utils/samplesheet_validation'
include { FASTQ_VALIDATOR          } from '../modules/local/magma/fastqvalidator/main'
include { UTILS_FASTQ_COHORT_VALIDATION } from '../modules/local/magma/utils/fastq_cohort_validation'

// ── Mapping ────────────────────────────────────────────────────────────────────
include { BWA_MEM                  } from '../modules/local/magma/bwa/mem'

// ── Per-sample calling ─────────────────────────────────────────────────────────
include { SAMTOOLS_MERGE           } from '../modules/local/magma/nf-core/samtools/merge/main'
include { SAMTOOLS_INDEX           } from '../modules/local/magma/nf-core/samtools/index/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_LOFREQ } from '../modules/local/magma/nf-core/samtools/index/main'
include { SAMTOOLS_STATS           } from '../modules/local/magma/nf-core/samtools/stats/main'
include { GATK4_MARKDUPLICATES as GATK_MARK_DUPLICATES     } from '../modules/local/magma/nf-core/gatk4/markduplicates/main'
include { GATK4_BASERECALIBRATOR as GATK_BASE_RECALIBRATOR   } from '../modules/local/magma/nf-core/gatk4/baserecalibrator/main'
include { GATK4_APPLYBQSR as GATK_APPLY_BQSR          } from '../modules/local/magma/nf-core/gatk4/applybqsr/main'
include { GATK4_HAPLOTYPECALLER as GATK_HAPLOTYPE_CALLER    } from '../modules/local/magma/nf-core/gatk4/haplotypecaller/main'
include { GATK_COLLECT_WGS_METRICS } from '../modules/local/magma/gatk/collect_wgs_metrics'
include { GATK_FLAG_STAT           } from '../modules/local/magma/gatk/flag_stat'
include { LOFREQ_INDELQUAL         } from '../modules/local/magma/nf-core/lofreq/indelqual/main'
include { LOFREQ_CALL              } from '../modules/local/magma/lofreq/call'
include { LOFREQ_CALL_NTM          } from '../modules/local/magma/lofreq/call_ntm'
include { LOFREQ_FILTER            } from '../modules/local/magma/nf-core/lofreq/filter/main'
include { UTILS_SAMPLE_STATS       } from '../modules/local/magma/utils/sample_stats'
include { UTILS_COHORT_STATS       } from '../modules/local/magma/utils/cohort_stats'
include { UTILS_REFORMAT_LOFREQ    } from '../modules/local/magma/utils/reformat_lofreq'
include { GATK4_INDEXFEATUREFILE as GATK_INDEX_FEATURE_FILE_LOFREQ } from '../modules/local/magma/nf-core/gatk4/indexfeaturefile/main'
include { BGZIP as BGZIP_LOFREQ    } from '../modules/local/magma/bgzip/bgzip'
include { UTILS_MERGE_COHORT_STATS } from '../modules/local/magma/utils/merge_cohort_stats'

// ── QC (FastQC, NTMprofiler, TBprofiler fastq, SpoTyping) ─────────────────────
include { NTMPROFILER_PROFILE      } from '../modules/local/magma/ntmprofiler/profile'
include { NTMPROFILER_COLLATE      } from '../modules/local/magma/ntmprofiler/collate'
include { TBPROFILER_FASTQ_PROFILE } from '../modules/local/magma/tbprofiler/fastq_profile'
include { TBPROFILER_COLLATE as TBPROFILER_FASTQ_COLLATE } from '../modules/local/magma/tbprofiler/collate'
include { SPOTYPING                } from '../modules/local/magma/spotyping/main'
include { UTILS_CAT_SPOTYPING      } from '../modules/local/magma/utils/cat_spotyping'

// ── Structural variants (DELLY) ────────────────────────────────────────────────
include { BWA_MEM as BWA_MEM_DELLY               } from '../modules/local/magma/bwa/mem'
include { SAMTOOLS_MERGE as SAMTOOLS_MERGE_DELLY } from '../modules/local/magma/nf-core/samtools/merge/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_DELLY  } from '../modules/local/magma/nf-core/samtools/index/main'
include { GATK4_MARKDUPLICATES as GATK_MARK_DUPLICATES_DELLY   } from '../modules/local/magma/nf-core/gatk4/markduplicates/main'
include { GATK4_BASERECALIBRATOR as GATK_BASE_RECALIBRATOR_DELLY } from '../modules/local/magma/nf-core/gatk4/baserecalibrator/main'
include { GATK4_APPLYBQSR as GATK_APPLY_BQSR_DELLY              } from '../modules/local/magma/nf-core/gatk4/applybqsr/main'
include { DELLY_CALL               } from '../modules/local/magma/nf-core/delly/call/main'
include { BCFTOOLS_VIEW as BCFTOOLS_VIEW_DELLY   } from '../modules/local/magma/nf-core/bcftools/view/main'
include { BCFTOOLS_MERGE as BCFTOOLS_MERGE_DELLY } from '../modules/local/magma/bcftools/merge'
include { BGZIP as BGZIP_MINOR_VARIANTS          } from '../modules/local/magma/bgzip/bgzip'
include { BCFTOOLS_MERGE as BCFTOOLS_MERGE_LOFREQ } from '../modules/local/magma/bcftools/merge'

// ── TB drug-resistance & structural variant profiles ──────────────────────────
include { TBPROFILER_VCF_PROFILE as TBPROFILER_VCF_PROFILE_DELLY  } from '../modules/local/magma/tbprofiler/vcf_profile'
include { TBPROFILER_COLLATE as TBPROFILER_COLLATE_DELLY           } from '../modules/local/magma/tbprofiler/collate'
include { TBPROFILER_VCF_PROFILE as TBPROFILER_VCF_PROFILE_LOFREQ } from '../modules/local/magma/tbprofiler/vcf_profile'
include { TBPROFILER_COLLATE as TBPROFILER_COLLATE_LOFREQ          } from '../modules/local/magma/tbprofiler/collate'
include { UTILS_MULTIPLE_INFECTION_FILTER } from '../modules/local/magma/utils/multiple_infection_filter'

// ── Cohort joint-genotyping subworkflows ──────────────────────────────────────
include { PREPARE_COHORT_VCF     } from '../subworkflows/local/magma/prepare_cohort_vcf'
include { SNP_ANALYSIS           } from '../subworkflows/local/magma/snp_analysis'
include { INDEL_ANALYSIS         } from '../subworkflows/local/magma/indel_analysis'
include { MAJOR_VARIANT_ANALYSIS } from '../subworkflows/local/magma/major_variant_analysis'
include { PHYLOGENY_ANALYSIS as PHYLOGENY_ANALYSIS_INCCOMPLEX } from '../subworkflows/local/magma/phylogeny_analysis'
include { PHYLOGENY_ANALYSIS as PHYLOGENY_ANALYSIS_EXCOMPLEX  } from '../subworkflows/local/magma/phylogeny_analysis'
include { CLUSTER_ANALYSIS as CLUSTER_ANALYSIS_INCCOMPLEX    } from '../subworkflows/local/magma/cluster_analysis'
include { CLUSTER_ANALYSIS as CLUSTER_ANALYSIS_EXCOMPLEX     } from '../subworkflows/local/magma/cluster_analysis'

// ── Final merge + reports ──────────────────────────────────────────────────────
include { GATK4_MERGEVCFS as GATK_MERGE_VCFS_INC      } from '../modules/local/magma/nf-core/gatk4/mergevcfs/main'
include { UTILS_SUMMARIZE_RESISTANCE_RESULTS           } from '../modules/local/magma/utils/summarize_resistance_results'
include { UTILS_SUMMARIZE_RESISTANCE_RESULTS_MIXED_INFECTION } from '../modules/local/magma/utils/summarize_resistance_results_mixed_infection'

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

    def ch_versions      = channel.empty()
    def ch_multiqc_files = channel.empty()

    // =========================================================================
    // SAMPLESHEET VALIDATION + FASTQ VALIDATION
    // NOTE: MAGMA uses its own CSV format (study, sample, library, …, r1, r2).
    //       We run SAMPLESHEET_VALIDATION directly on params.magma_input_samplesheet
    //       rather than relying on the nf-schema-parsed ch_samplesheet, which
    //       expects a different schema.
    // =========================================================================

    SAMPLESHEET_VALIDATION(file(params.magma_input_samplesheet ?: params.input, checkIfExists: true))

    // Build a per-FASTQ-file channel from the validated JSON
    fastqs_ch = SAMPLESHEET_VALIDATION.out.validated_samplesheet
        .splitJson()
        .map { row ->
            def meta = [
                id:             row.magma_sample_name,
                bam_rg_string:  row.magma_bam_rg_string,
                paired:         row.R2 ? true : false,
                single_end:     row.R2 ? false : true
            ]
            row.R2 ? [ meta, [row.R1, row.R2] ] : [ meta, [row.R1] ]
        }
        .transpose()   // emit one record per fastq file

    // Validate each FASTQ individually
    FASTQ_VALIDATOR(fastqs_ch, SAMPLESHEET_VALIDATION.out.status)

    // Cohort-level validation (QC cutoffs, contamination check)
    UTILS_FASTQ_COHORT_VALIDATION(
        FASTQ_VALIDATOR.out.fastq_report.collect(),
        SAMPLESHEET_VALIDATION.out.validated_samplesheet
    )

    // Build approved-samples channel from magma_analysis.json
    approved_fastqs_ch = UTILS_FASTQ_COHORT_VALIDATION.out.magma_analysis_json
        .splitJson()
        .filter { it.value.fastqs_approved }
        .map { row ->
            def meta = [
                id:            row.value.magma_sample_name,
                bam_rg_string: row.value.magma_bam_rg_string,
                paired:        row.value.R2 ? true : false,
                single_end:    row.value.R2 ? false : true
            ]
            row.value.R2 ? [ meta, [row.value.R1, row.value.R2] ] : [ meta, [row.value.R1] ]
        }

    // =========================================================================
    // QUALITY CHECK (FastQC, NTMprofiler, TBprofiler FASTQ, SpoTyping)
    // =========================================================================

    FASTQC(approved_fastqs_ch)
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.map { _meta, file -> file })

    if (!params.magma_skip_ntmprofiler) {
        NTMPROFILER_PROFILE(approved_fastqs_ch)
        NTMPROFILER_COLLATE(params.magma_vcf_name, NTMPROFILER_PROFILE.out.profile_json.collect())
    }

    if (!params.magma_skip_tbprofiler_fastq) {
        TBPROFILER_FASTQ_PROFILE(approved_fastqs_ch)
        TBPROFILER_FASTQ_COLLATE(
            params.magma_vcf_name,
            TBPROFILER_FASTQ_PROFILE.out.json.map { _meta, j -> j }.collect(),
            []
        )
    }

    if (!params.magma_skip_spotyping) {
        SPOTYPING(approved_fastqs_ch)
        UTILS_CAT_SPOTYPING(SPOTYPING.out.txt.collect())
    }

    // =========================================================================
    // EARLY EXIT: only_validate_fastqs mode
    // =========================================================================

    if (!params.magma_only_validate_fastqs) {

        // =====================================================================
        // MAPPING — BWA (main pipeline)
        // =====================================================================

        BWA_MEM(
            approved_fastqs_ch,
            params.magma_ref_fasta,
            [params.magma_ref_fasta_dict, params.magma_ref_fasta_amb, params.magma_ref_fasta_ann,
             params.magma_ref_fasta_bwt, params.magma_ref_fasta_fai, params.magma_ref_fasta_pac,
             params.magma_ref_fasta_sa]
        )

        // =====================================================================
        // CALL_WF — per-sample variant calling
        // =====================================================================

        // Group by sample (collapse per-library BAMs into one tuple per sample)
        normalize_libraries_ch = BWA_MEM.out
            .map { meta, bam ->
                def splitted = meta.id.split("\\.")
                def sampleId = splitted[0] + '.' + splitted[1]
                [ meta + [id: sampleId], bam ]
            }
            .groupTuple()

        // nf-core SAMTOOLS_MERGE adds index_files + fasta value tuple inputs;
        // for BAM-only merging both are empty. Pad and pass an empty fasta tuple.
        def samtools_merge_input_ch = normalize_libraries_ch.map { meta, bams -> [meta, bams, []] }
        def samtools_merge_ref_ch   = Channel.value([ [id: 'none'], [], [], [] ])
        SAMTOOLS_MERGE(samtools_merge_input_ch, samtools_merge_ref_ch)

        // nf-core gatk4/markduplicates also takes (optional) fasta/fai for CRAM
        // conversion; we run in BAM mode so pass [] for both.
        GATK_MARK_DUPLICATES(SAMTOOLS_MERGE.out.bam, [], [])

        // BQSR (disabled by default for Mtb) — uses standard nf-core modules.
        // nf-core's BaseRecalibrator wants [meta, bam, bai, intervals]; we have
        // [meta, bam]. Pad with [] for bai (gatk auto-indexes input on the fly)
        // and intervals. fasta/fai/dict/dbsnp/dbsnp_tbi all wrapped as value
        // tuples. ApplyBQSR has a similar shape and takes the BQSR table joined
        // back with the original bam.
        if (!params.magma_skip_base_recalibration) {
            def base_recal_input_ch = GATK_MARK_DUPLICATES.out.bam.map { meta, bam -> [ meta, bam, [], [] ] }
            GATK_BASE_RECALIBRATOR(
                base_recal_input_ch,
                Channel.value([ [id:'ref'],   file(params.magma_ref_fasta)      ]),
                Channel.value([ [id:'ref'],   file(params.magma_ref_fasta_fai)  ]),
                Channel.value([ [id:'ref'],   file(params.magma_ref_fasta_dict) ]),
                Channel.value([ [id:'dbsnp'], file(params.magma_dbsnp_vcf)      ]),
                Channel.value([ [id:'dbsnp'], file(params.magma_dbsnp_vcf_tbi)  ])
            )
            // ApplyBQSR input: [meta, bam, bai, bqsr_table, intervals]
            def apply_bqsr_input_ch = GATK_BASE_RECALIBRATOR.out.table
                .join(GATK_MARK_DUPLICATES.out.bam)
                .map { meta, table, bam -> [ meta, bam, [], table, [] ] }
            GATK_APPLY_BQSR(
                apply_bqsr_input_ch,
                file(params.magma_ref_fasta),
                file(params.magma_ref_fasta_fai),
                file(params.magma_ref_fasta_dict)
            )
            recalibrated_bam_ch = GATK_APPLY_BQSR.out.bam
        } else {
            recalibrated_bam_ch = GATK_MARK_DUPLICATES.out.bam
        }

        SAMTOOLS_INDEX(recalibrated_bam_ch)

        // Rebuild the [meta, bai, bam] tuple that downstream local modules
        // (GATK_HAPLOTYPE_CALLER, LOFREQ_CALL_NTM, etc.) expect — the local
        // SAMTOOLS_INDEX emitted that 3-tuple directly, but the standard nf-core
        // module emits only [meta, bai] (emit: index). We join it back with
        // recalibrated_bam_ch on meta to recover the original shape.
        def recalibrated_indexed_bam_ch = SAMTOOLS_INDEX.out.index.join(recalibrated_bam_ch)

        // HaplotypeCaller (major variants / GVCF).
        // nf-core HC input: [meta, bam, bai, intervals, dragstr_model]
        // + 5 ref value tuples (fasta/fai/dict/dbsnp/dbsnp_tbi — last 2 empty).
        // Reorder our [meta, bai, bam] → [meta, bam, bai, [], []].
        def haplotype_caller_input_ch = recalibrated_indexed_bam_ch.map { meta, bai, bam -> [ meta, bam, bai, [], [] ] }
        GATK_HAPLOTYPE_CALLER(
            haplotype_caller_input_ch,
            Channel.value([ [id: 'ref'],   file(params.magma_ref_fasta)      ]),
            Channel.value([ [id: 'ref'],   file(params.magma_ref_fasta_fai)  ]),
            Channel.value([ [id: 'ref'],   file(params.magma_ref_fasta_dict) ]),
            Channel.value([ [id: 'none'],  [] ]),
            Channel.value([ [id: 'none'],  [] ])
        )

        // NTM contamination estimate via LoFreq call at 16S locus
        LOFREQ_CALL_NTM(
            recalibrated_indexed_bam_ch,
            params.magma_ref_fasta,
            [params.magma_ref_fasta_fai]
        )

        // LoFreq minor-variant calling.
        // nf-core LOFREQ_INDELQUAL takes the reference as a value tuple
        // (tuple val(meta2), path(fasta)); wrap params.magma_ref_fasta accordingly.
        def lofreq_indelqual_ref_ch = Channel.value([ [id: 'ref'], file(params.magma_ref_fasta) ])
        LOFREQ_INDELQUAL(recalibrated_bam_ch, lofreq_indelqual_ref_ch)
        SAMTOOLS_INDEX_LOFREQ(LOFREQ_INDELQUAL.out.bam)
        // Same [meta, bai, bam] rebuild as above — LOFREQ_CALL expects the 3-tuple.
        def lofreq_indexed_bam_ch = SAMTOOLS_INDEX_LOFREQ.out.index.join(LOFREQ_INDELQUAL.out.bam)
        LOFREQ_CALL(lofreq_indexed_bam_ch, params.magma_ref_fasta, [params.magma_ref_fasta_fai])
        // nf-core LOFREQ_FILTER takes only (tuple val(meta), path(vcf)) — the
        // reference fasta isn't needed by `lofreq filter`. Drop the params.magma_ref_fasta
        // arg that the local module accepted but never used.
        LOFREQ_FILTER(LOFREQ_CALL.out)

        // Reformat LoFreq VCFs for downstream merging
        UTILS_REFORMAT_LOFREQ(LOFREQ_CALL.out)
        BGZIP_LOFREQ(UTILS_REFORMAT_LOFREQ.out)
        GATK_INDEX_FEATURE_FILE_LOFREQ(BGZIP_LOFREQ.out)
        // nf-core gatk4/indexfeaturefile emits [meta, tbi] (emit: index).
        // Downstream wants the local module's `vcf_tuple` emit shape, which
        // dropped meta and was [tbi, vcf]. Rebuild it by joining the index
        // emit with BGZIP_LOFREQ.out (the same vcf channel that fed the indexer).
        def lofreq_vcf_tuple_pairs_ch = GATK_INDEX_FEATURE_FILE_LOFREQ.out.index
            .join(BGZIP_LOFREQ.out)
            .map { _meta, tbi, vcf -> [ tbi, vcf ] }

        // Per-sample QC stats — SAMTOOLS_STATS uses the standard nf-core module.
        // nf-core's signature is (meta, input, input_index) + (meta2, fasta, fai),
        // so we pad the bam-only channel with `[]` for the index (samtools stats
        // doesn't require one) and pass the reference as a value tuple.
        def samtools_stats_input_ch = recalibrated_bam_ch.map { meta, bam -> [meta, bam, []] }
        def samtools_stats_ref_ch   = Channel.value([ [id: 'ref'], file(params.magma_ref_fasta), file(params.magma_ref_fasta_fai) ])
        SAMTOOLS_STATS(samtools_stats_input_ch, samtools_stats_ref_ch)
        GATK_COLLECT_WGS_METRICS(recalibrated_bam_ch, params.magma_ref_fasta)
        GATK_FLAG_STAT(recalibrated_bam_ch, params.magma_ref_fasta, [params.magma_ref_fasta_fai, params.magma_ref_fasta_dict])

        sample_stats_ch = SAMTOOLS_STATS.out.stats
            .join(GATK_COLLECT_WGS_METRICS.out)
            .join(GATK_FLAG_STAT.out)
            .join(LOFREQ_CALL_NTM.out)

        UTILS_SAMPLE_STATS(sample_stats_ch)
        UTILS_COHORT_STATS(UTILS_SAMPLE_STATS.out.collect())

        // =====================================================================
        // MINOR VARIANTS ANALYSIS (LoFreq cohort merge + TBprofiler)
        // =====================================================================

        lofreq_vcf_tuple_ch = lofreq_vcf_tuple_pairs_ch.collect(sort: true)

        vcfs_file = lofreq_vcf_tuple_ch
            .flatten()
            .filter { it instanceof java.nio.file.Path && it.getExtension() == "gz" }
            .map { it.name }
            .collectFile(name: "${outdir}/minor_variant_vcfs.txt", newLine: true)

        BCFTOOLS_MERGE_LOFREQ(
            params.magma_vcf_name,
            'lofreq',
            vcfs_file,
            lofreq_vcf_tuple_ch
                .flatten()
                .filter { it instanceof java.nio.file.Path }
                .collect()
        )

        def resistanceDb = []
        TBPROFILER_VCF_PROFILE_LOFREQ(BCFTOOLS_MERGE_LOFREQ.out, resistanceDb)
        TBPROFILER_COLLATE_LOFREQ(
            params.magma_vcf_name,
            TBPROFILER_VCF_PROFILE_LOFREQ.out.collect(),
            resistanceDb
        )
        UTILS_MULTIPLE_INFECTION_FILTER(TBPROFILER_COLLATE_LOFREQ.out.per_sample_results)

        UTILS_MERGE_COHORT_STATS(
            UTILS_MULTIPLE_INFECTION_FILTER.out.approved_samples,
            UTILS_MULTIPLE_INFECTION_FILTER.out.rejected_samples,
            UTILS_COHORT_STATS.out
        )

        // MultiQC (MAGMA): the merged cohort stats feed preprocess_multiqc_input.py
        ch_multiqc_files = ch_multiqc_files.mix(UTILS_MERGE_COHORT_STATS.out.merged_cohort_stats_ch)

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

        BWA_MEM_DELLY(
            approved_fastqs_ch,
            params.magma_ref_fasta,
            [params.magma_ref_fasta_dict, params.magma_ref_fasta_amb, params.magma_ref_fasta_ann,
             params.magma_ref_fasta_bwt, params.magma_ref_fasta_fai, params.magma_ref_fasta_pac,
             params.magma_ref_fasta_sa]
        )

        delly_normalize_ch = BWA_MEM_DELLY.out
            .map { meta, bam ->
                def splitted = meta.id.split("\\.")
                def sampleId = splitted[0] + '.' + splitted[1]
                [ meta + [id: sampleId], bam ]
            }
            .groupTuple()

        // Join with approved samples to filter.
        // Shapes after join:
        //   all_samples_ch.map { [it[0], it[0]] }                       → [id, id]
        //   delly_normalize_ch.map { meta, bam -> [meta.id, meta, bam] } → [id, meta, [bams]]
        //   join (key=id)                                                → [id, id, meta, [bams]]
        // The previous 3-arg destructure dropped the second id, causing
        // 'Invalid method invocation `call` with arguments: [id, id, meta, [bam]]'.
        delly_filtered_ch = all_samples_ch
            .map { [ it[0], it[0] ] }
            .join(delly_normalize_ch.map { meta, bam -> [ meta.id, meta, bam ] })
            .map { _id, _id2, meta, bam -> [ meta, bam ] }

        def samtools_merge_delly_input_ch = delly_filtered_ch.map { meta, bams -> [meta, bams, []] }
        SAMTOOLS_MERGE_DELLY(samtools_merge_delly_input_ch, Channel.value([ [id: 'none'], [], [], [] ]))
        GATK_MARK_DUPLICATES_DELLY(SAMTOOLS_MERGE_DELLY.out.bam, [], [])

        if (!params.magma_skip_base_recalibration) {
            def base_recal_delly_input_ch = GATK_MARK_DUPLICATES_DELLY.out.bam.map { meta, bam -> [ meta, bam, [], [] ] }
            GATK_BASE_RECALIBRATOR_DELLY(
                base_recal_delly_input_ch,
                Channel.value([ [id:'ref'],   file(params.magma_ref_fasta)      ]),
                Channel.value([ [id:'ref'],   file(params.magma_ref_fasta_fai)  ]),
                Channel.value([ [id:'ref'],   file(params.magma_ref_fasta_dict) ]),
                Channel.value([ [id:'dbsnp'], file(params.magma_dbsnp_vcf)      ]),
                Channel.value([ [id:'dbsnp'], file(params.magma_dbsnp_vcf_tbi)  ])
            )
            def apply_bqsr_delly_input_ch = GATK_BASE_RECALIBRATOR_DELLY.out.table
                .join(GATK_MARK_DUPLICATES_DELLY.out.bam)
                .map { meta, table, bam -> [ meta, bam, [], table, [] ] }
            GATK_APPLY_BQSR_DELLY(
                apply_bqsr_delly_input_ch,
                file(params.magma_ref_fasta),
                file(params.magma_ref_fasta_fai),
                file(params.magma_ref_fasta_dict)
            )
            recal_delly_ch = GATK_APPLY_BQSR_DELLY.out.bam
        } else {
            recal_delly_ch = GATK_MARK_DUPLICATES_DELLY.out.bam
        }

        SAMTOOLS_INDEX_DELLY(recal_delly_ch)
        // Adapt to the nf-core DELLY_CALL signature, which takes a wide tuple
        //   (meta, input_bam, input_bai, vcf, vcf_index, exclude_bed)
        // with the last three optional, plus separate fasta + fai value tuples
        // and a 'bcf'/'vcf' suffix selector. MAGMA does discovery-mode DELLY
        // calls (no genotyping VCF, no exclude bed) and wants .bcf output.
        def delly_call_input_ch = SAMTOOLS_INDEX_DELLY.out.index
            .join(recal_delly_ch)
            .map { meta, bai, bam -> [ meta, bam, bai, [], [], [] ] }
        def delly_call_fasta_ch = Channel.value([ [id: 'ref'], file(params.magma_ref_fasta)     ])
        def delly_call_fai_ch   = Channel.value([ [id: 'ref'], file(params.magma_ref_fasta_fai) ])
        DELLY_CALL(delly_call_input_ch, delly_call_fasta_ch, delly_call_fai_ch, 'bcf')
        // nf-core BCFTOOLS_VIEW takes [meta, vcf, index] (the index can be passed
        // empty []); we have DELLY_CALL.out.bcf=[meta, bcf] and .csi=[meta, csi],
        // so join them. Optional regions/targets/samples are all empty.
        def bcftools_view_delly_input_ch = DELLY_CALL.out.bcf.join(DELLY_CALL.out.csi)
        BCFTOOLS_VIEW_DELLY(bcftools_view_delly_input_ch, [], [], [])

        // The local module emitted a 3-tuple [meta, bcf.gz, csi] which the
        // downstream pipeline flattened and filtered. The nf-core module emits
        // .vcf (the filtered file) and .index (the auto-generated csi from
        // --write-index=csi) separately; join+flatten the same way.
        def bcftools_view_delly_out_ch = BCFTOOLS_VIEW_DELLY.out.vcf.join(BCFTOOLS_VIEW_DELLY.out.index)

        delly_vcfs_ch = bcftools_view_delly_out_ch
            .collect()
            .flatten()
            .filter { it instanceof java.nio.file.Path }
            .unique()
            .collect(sort: true)

        delly_vcfs_file = bcftools_view_delly_out_ch
            .collect()
            .flatten()
            .filter { it instanceof java.nio.file.Path && it.getExtension() == "gz" }
            .map { it.name }
            .collectFile(name: "${outdir}/structural_variant_vcfs.txt", newLine: true)

        BCFTOOLS_MERGE_DELLY(
            params.magma_vcf_name,
            'delly',
            delly_vcfs_file,
            delly_vcfs_ch
        )

        TBPROFILER_VCF_PROFILE_DELLY(BCFTOOLS_MERGE_DELLY.out, resistanceDb)
        TBPROFILER_COLLATE_DELLY(
            params.magma_vcf_name,
            TBPROFILER_VCF_PROFILE_DELLY.out.collect(),
            resistanceDb
        )

        // =====================================================================
        // MERGE_WF — cohort joint-genotyping + phylogeny
        // =====================================================================

        if (!params.magma_skip_merge_analysis) {

            // Build gvcf channel keyed on the sample name so it can join the
            // approved-samples channel (which carries sample-name Strings).
            // Port note: GATK_HAPLOTYPE_CALLER.out.gvcf_ch is [meta_MAP, tbi, gvcf];
            // torch-magma's equivalent was [sampleName_STR, tbi, gvcf] (which is
            // why a 3-element collate worked there with a String key). After
            // .collect().flatten() we re-collate to 3 and project the meta map
            // to its id so the .join key matches approved_samples_ch [sampleName].
            //
            // Without this fix the join silently produced an empty channel
            // (meta map ≠ string), the entire merge_wf (PREPARE_COHORT_VCF,
            // SNP_ANALYSIS, INDEL_ANALYSIS, MAJOR_VARIANT_ANALYSIS,
            // PHYLOGENY_*, CLUSTER_*) never fired, and MULTIQC failed at
            // preprocess_multiqc_input.py for missing joint.ExDR.ExComplex.snp_dists.tsv.
            // After the nf-core migration GATK_HAPLOTYPE_CALLER emits .vcf and
            // .tbi as separate channels; rebuild the [meta, tbi, vcf] 3-tuple
            // the existing .flatten/.collate(3) pipeline expects.
            collated_gvcfs_ch = GATK_HAPLOTYPE_CALLER.out.tbi
                .join(GATK_HAPLOTYPE_CALLER.out.vcf)
                .collect()
                .flatten()
                .collate(3)
                .map { meta, tbi, vcf -> [ meta.id, tbi, vcf ] }

            // Filter to approved samples only
            selected_gvcfs_ch = collated_gvcfs_ch
                .join(approved_samples_ch.map { [it[0], it[0]] })
                .flatten()
                .filter { it instanceof java.nio.file.Path }
                .collect()

            PREPARE_COHORT_VCF(selected_gvcfs_ch)

            SNP_ANALYSIS(PREPARE_COHORT_VCF.out.cohort_vcf_and_index_ch)
            INDEL_ANALYSIS(PREPARE_COHORT_VCF.out.cohort_vcf_and_index_ch)

            // Build the SNP+INDEL VCF channel for MergeVcfs. The join produces
            // [meta, snp_tbi, snp_vcf, indel_tbi, indel_vcf]; nf-core wants
            // [meta, [vcfs...]] (a list of VCFs to merge).
            def merge_inc_vcf_ch = SNP_ANALYSIS.out.snp_inc_vcf_ch
                .join(INDEL_ANALYSIS.out.indel_vcf_ch)
                .map { meta, _snp_tbi, snp_vcf, _indel_tbi, indel_vcf -> [ meta, [ snp_vcf, indel_vcf ] ] }

            // nf-core gatk4/mergevcfs also takes an (optional) dict value tuple
            // for --SEQUENCE_DICTIONARY; pass an empty tuple — MAGMA's merge
            // doesn't use a dict (torch-magma's command never had one).
            GATK_MERGE_VCFS_INC(merge_inc_vcf_ch, Channel.value([ [id: 'none'], [] ]))

            // Rebuild the downstream [meta, tbi, vcf] tuple that MAJOR_VARIANT_ANALYSIS
            // expects from the two separate nf-core emits (vcf / tbi).
            def merge_inc_vcf_out_ch = GATK_MERGE_VCFS_INC.out.tbi.join(GATK_MERGE_VCFS_INC.out.vcf)

            MAJOR_VARIANT_ANALYSIS(merge_inc_vcf_out_ch, lofreq_vcf_tuple_ch)

            // ExComplex phylogeny (excludes DR loci + complex/repetitive regions)
            excomplex_exclude_interval_ref_ch = Channel.of(
                file(params.magma_coll2018_vcf),
                file(params.magma_coll2018_vcf_tbi),
                file(params.magma_excluded_loci_list)
            ).flatten()

            if (!params.magma_skip_phylogeny_and_clustering) {
                PHYLOGENY_ANALYSIS_EXCOMPLEX(
                    Channel.value('ExDR.ExComplex'),
                    excomplex_exclude_interval_ref_ch,
                    SNP_ANALYSIS.out.snp_exc_vcf_ch
                )

                CLUSTER_ANALYSIS_EXCOMPLEX(
                    PHYLOGENY_ANALYSIS_EXCOMPLEX.out.snpsites_tree_tuple,
                    Channel.value('ExDR.ExComplex')
                )

                // MultiQC (MAGMA): the ExComplex SNP-distance matrix feeds
                // preprocess_multiqc_input.py (joint.ExDR.ExComplex.snp_dists.tsv)
                ch_multiqc_files = ch_multiqc_files.mix(PHYLOGENY_ANALYSIS_EXCOMPLEX.out.snp_dists_ch)
            }

            // IncComplex phylogeny (excludes DR loci only)
            if (!params.magma_skip_complex_regions && !params.magma_skip_phylogeny_and_clustering) {
                inccomplex_exclude_interval_ref_ch = Channel.of(
                    file(params.magma_coll2018_vcf),
                    file(params.magma_coll2018_vcf_tbi)
                ).flatten()

                PHYLOGENY_ANALYSIS_INCCOMPLEX(
                    Channel.value('ExDR.IncComplex'),
                    inccomplex_exclude_interval_ref_ch,
                    SNP_ANALYSIS.out.snp_exc_vcf_ch
                )

                CLUSTER_ANALYSIS_INCCOMPLEX(
                    PHYLOGENY_ANALYSIS_INCCOMPLEX.out.snpsites_tree_tuple,
                    Channel.value('ExDR.IncComplex')
                )
            }

            // Final resistance summary reports
            UTILS_SUMMARIZE_RESISTANCE_RESULTS(
                UTILS_MERGE_COHORT_STATS.out.merged_cohort_stats_ch,
                MAJOR_VARIANT_ANALYSIS.out.major_variants_results_ch,
                TBPROFILER_COLLATE_LOFREQ.out.per_sample_results,
                TBPROFILER_COLLATE_DELLY.out.per_sample_results
            )

            UTILS_SUMMARIZE_RESISTANCE_RESULTS_MIXED_INFECTION(
                UTILS_MERGE_COHORT_STATS.out.merged_cohort_stats_ch,
                TBPROFILER_COLLATE_LOFREQ.out.per_sample_results,
                TBPROFILER_COLLATE_DELLY.out.per_sample_results
            )

        } // end !skip_merge_analysis
    } // end !only_validate_fastqs

    // =========================================================================
    // Collate and save software versions
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

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name:  'magma_software_mqc_versions.yml',
            sort: true,
            newLine: true
        )

    // =========================================================================
    // MultiQC — faithful to standard MAGMA (preprocess_multiqc_input.py + multiqc)
    // =========================================================================
    // Note: ch_collated_versions above is still published to pipeline_info. We do
    // NOT mix the nf-core boilerplate (versions / workflow-summary / methods) into
    // the MULTIQC input — standard MAGMA feeds MULTIQC only the FASTQC reports,
    // the merged cohort stats and the ExComplex SNP-distance matrix (mixed in
    // above), matching the reference .command.sh exactly.

    MULTIQC(
        multiqc_config
            ? file(multiqc_config, checkIfExists: true)
            : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
        ch_multiqc_files.flatten().collect()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList()
    versions       = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

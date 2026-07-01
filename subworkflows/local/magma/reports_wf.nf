/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    REPORTS_WF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Final resistance-summary tables + MultiQC report.  Mirrors torch-magma's
    workflows/reports_wf.nf.
*/

include { UTILS_SUMMARIZE_RESISTANCE_RESULTS                 } from '../../../modules/local/magma/utils/summarize_resistance_results'
include { UTILS_SUMMARIZE_RESISTANCE_RESULTS_MIXED_INFECTION } from '../../../modules/local/magma/utils/summarize_resistance_results_mixed_infection'
include { MULTIQC                                            } from '../../../modules/local/magma/multiqc/main'


workflow REPORTS_WF {

    take:
    reports_fastqc_ch                // channel: per-sample FASTQC zip paths
    merged_cohort_stats_ch           // channel: cohort QC tsv (from UTILS_MERGE_COHORT_STATS)
    major_variants_results_ch        // channel: TBprofiler cohort per-sample results
    minor_variants_results_ch        // channel: TBprofiler LoFreq per-sample results
    structural_variants_results_ch   // channel: TBprofiler DELLY per-sample results
    snp_distances_ch                 // channel: ExComplex SNP-distance matrix (.tsv)
    multiqc_config                   // param  : optional multiqc config path

    main:

    UTILS_SUMMARIZE_RESISTANCE_RESULTS(
        merged_cohort_stats_ch,
        major_variants_results_ch,
        minor_variants_results_ch,
        structural_variants_results_ch
    )

    UTILS_SUMMARIZE_RESISTANCE_RESULTS_MIXED_INFECTION(
        merged_cohort_stats_ch,
        minor_variants_results_ch,
        structural_variants_results_ch
    )

    // MAGMA's MULTIQC takes only the FASTQC reports, the merged cohort stats
    // and the ExComplex SNP-distance matrix (faithful to standard MAGMA).
    def ch_multiqc_files = channel.empty()
        .mix(reports_fastqc_ch)
        .mix(merged_cohort_stats_ch)
        .mix(snp_distances_ch)

    MULTIQC(
        multiqc_config
            ? file(multiqc_config, checkIfExists: true)
            : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
        ch_multiqc_files.flatten().collect()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList()
}

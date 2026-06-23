process UTILS_MERGE_COHORT_STATS {
    label 'process_single'

    input:
        path(approved_samples_tsv)
        path(rejected_samples_tsv)
        path(call_wf_cohort_stats_tsv)

    output:
        path("*merged_cohort_stats.tsv"), emit: merged_cohort_stats_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    generate_merged_cohort_stats.py \\
        --relabundance_approved_tsv ${approved_samples_tsv} \\
        --relabundance_rejected_tsv ${rejected_samples_tsv} \\
        --call_wf_cohort_stats_tsv ${call_wf_cohort_stats_tsv} \\
        --output_file ${params.magma_vcf_name}.merged_cohort_stats.tsv
    """

    stub:
    """
    touch ${params.magma_vcf_name}.merged_cohort_stats.tsv
    """
}

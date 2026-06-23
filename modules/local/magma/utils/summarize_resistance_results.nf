process UTILS_SUMMARIZE_RESISTANCE_RESULTS {
    label 'process_single'
    stageInMode 'copy'

    input:
        path(merge_cohort_stats)
        path("major_variants/*")
        path("minor_variants/*")
        path("structural_variants/*")

    output:
        path("combined_resistance_summaries")

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    summarize_resistance.py ${merge_cohort_stats} major_variants minor_variants structural_variants combined_resistance_summaries
    """

    stub:
    """
    mkdir combined_resistance_summaries
    """
}

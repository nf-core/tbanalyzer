process UTILS_SUMMARIZE_RESISTANCE_RESULTS_MIXED_INFECTION {
    label 'process_single'
    stageInMode 'copy'

    input:
        path(merge_cohort_stats)
        path("minor_variants/*")
        path("structural_variants/*")

    output:
        path("combined_resistance_summaries_mixed_infection_samples"), optional: true

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    summarize_resistance_mixed_infection.py ${merge_cohort_stats} minor_variants structural_variants combined_resistance_summaries_mixed_infection_samples
    """

    stub:
    """
    mkdir combined_resistance_summaries_mixed_infection_samples
    """
}

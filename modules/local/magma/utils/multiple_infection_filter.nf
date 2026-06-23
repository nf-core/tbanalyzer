process UTILS_MULTIPLE_INFECTION_FILTER {
    label 'process_single'
    stageInMode "copy"

    input:
        path("per_sample_results")

    output:
        path("approved_samples.relabundance.tsv"), emit: approved_samples
        path("rejected_samples.relabundance.tsv"), emit: rejected_samples

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    multiple_infection_filter.py per_sample_results ${params.magma_cutoff_rel_abundance}
    """

    stub:
    """
    touch approved_samples.relabundance.tsv
    touch rejected_samples.relabundance.tsv
    """
}

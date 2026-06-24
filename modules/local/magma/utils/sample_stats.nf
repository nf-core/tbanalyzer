process UTILS_SAMPLE_STATS {
    tag "${meta.id}"
    label 'process_single'

    input:
        tuple val(meta), path(samtoolsStats), path(wgsMetrics), path(flagStats), path(ntmFraction)

    output:
        path("*.stats.tsv"), emit: stats

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    sample_stats.py \\
        --sample_name ${meta.id} \\
        --flagstat_file ${flagStats} \\
        --samtoolsstats_file ${samtoolsStats} \\
        --wgsmetrics_file ${wgsMetrics} \\
        --ntmfraction_file ${ntmFraction} \\
        --cutoff_median_coverage ${params.magma_cutoff_median_coverage} \\
        --cutoff_breadth_of_coverage ${params.magma_cutoff_breadth_of_coverage} \\
        --cutoff_ntm_fraction ${params.magma_cutoff_ntm_fraction}
    """

    stub:
    """
    touch ${meta.id}.stats.tsv
    """
}

process GATK_COLLECT_WGS_METRICS {
    tag "${meta.id}"
    label 'process_low'

    input:
        tuple val(meta), path(bam)
        path(reference)

    output:
        tuple val(meta), path("*.WgsMetrics.txt"), emit: metrics

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    gatk CollectWgsMetrics --java-options "-Xmx${task.memory.giga}G" \\
        -R ${reference} \\
        -I ${bam} \\
        ${args} \\
        -O ${meta.id}.WgsMetrics.txt
    """

    stub:
    """
    touch ${meta.id}.WgsMetrics.txt
    """
}

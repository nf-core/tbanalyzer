process GATK_FLAG_STAT {
    tag "${meta.id}"
    label 'process_low'

    input:
        tuple val(meta), path(bam)
        path(ref_fasta)
        path("*")

    output:
        tuple val(meta), path("*.FlagStat.txt")

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    gatk FlagStat --java-options "-Xmx${task.memory.giga}G" \\
        -R ${ref_fasta} \\
        -I ${bam} \\
    > ${meta.id}.FlagStat.txt
    """

    stub:
    """
    touch ${meta.id}.FlagStat.txt
    """
}

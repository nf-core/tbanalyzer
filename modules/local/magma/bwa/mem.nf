process BWA_MEM {
    tag "${meta.id}"
    label 'process_medium'

    input:
        tuple val(meta), path(sampleReads)
        path(reference)
        path("*")

    output:
        tuple val(meta), path("*.sorted_reads.bam"), emit: bam

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    """
    bwa mem \\
        ${args} \\
        ${args2} \\
        -t ${task.cpus} \\
        -R "${meta.bam_rg_string}" \\
        ${reference} \\
        ${sampleReads} \\
    | samtools sort \\
        -@ ${task.cpus} \\
        -O BAM \\
        -o ${meta.id}.sorted_reads.bam -

    """

    stub:
    """
    touch ${meta.id}.sorted_reads.bam
    """
}

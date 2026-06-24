process LOFREQ_CALL {
    tag "${meta.id}"
    label 'process_medium'

    input:
        tuple val(meta), path(bamIndex), path(bam)
        path(reference)
        path("*")

    output:
        tuple val(meta), path("*.LoFreq.vcf"), emit: vcf

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args  ?: ''
    def region = task.ext.args2 ?: ''
    def regionArg = region ? "-r ${reference.getBaseName()}:${region}" : ''
    """
    lofreq call-parallel \\
        -f ${reference} \\
        --pp-threads ${task.cpus} \\
        ${regionArg} \\
        ${args} \\
        ${bam} \\
        -o ${meta.id}.LoFreq.vcf
    """

    stub:
    """
    touch ${meta.id}.LoFreq.vcf
    """
}

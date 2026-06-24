process BGZIP {
    tag "${meta.id}"
    label 'process_low'

    input:
        tuple val(meta), path(vcf)

    output:
        tuple val(meta), path("*.gz"), emit: vcf

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    bgzip ${args} ${vcf}
    """

    stub:
    """
    touch ${meta.id}.annotated.vcf.gz
    """
}

process SNPSITES {
    tag "${meta.id}"
    label 'process_low'

    input:
        val(prefix)
        tuple val(meta), path(alignmentFasta)

    output:
        tuple val(meta), path("*.variable.${prefix}.fa"), emit: fasta

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    snp-sites -o ${meta.id}.variable.${prefix}.fa ${alignmentFasta}
    """

    stub:
    """
    touch ${meta.id}.variable.${prefix}.fa
    """
}

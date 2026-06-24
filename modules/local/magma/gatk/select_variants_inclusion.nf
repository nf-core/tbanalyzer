process GATK_SELECT_VARIANTS_INCLUSION {
    tag "${meta.id}"
    label 'process_low'

    input:
        tuple val(meta), path(structuralVariantsIndex), path(structuralVariantsVcf)
        path(intervalsFile)

    output:
        path("${meta.id}.potentialSV.DRgenes.vcf.gz"), emit: vcf

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    gatk SelectVariants --java-options "-Xmx${task.memory.giga}G" \\
        -V ${structuralVariantsVcf} \\
        -L ${intervalsFile} \\
        -O ${meta.id}.potentialSV.DRgenes.vcf.gz
    """

    stub:
    """
    touch ${meta.id}.potentialSV.DRgenes.vcf.gz
    """
}

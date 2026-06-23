process GATK_SELECT_VARIANTS {
    tag "${meta.id}"
    label 'process_medium'

    input:
        val(variantType)
        val(prefix)
        tuple val(meta), path(vcfIndex), path(vcf)
        val(resourceFilesArg)
        path(resourceFiles)
        path(resourceFileIndexes)
        path(reference)
        path("*")

    output:
        tuple val(meta), path("*.${prefix}_${variantType}.vcf.gz.tbi"), path("*.${prefix}_${variantType}.vcf.gz"), emit: variantsVcfTuple

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def excludeIntervalsArg = resourceFilesArg != "" ? resourceFilesArg : ""
    """
    gatk SelectVariants --java-options "-Xmx${task.memory.giga}G" \\
        -R ${reference} \\
        -V ${vcf} \\
        --select-type-to-include ${variantType} \\
        ${excludeIntervalsArg} \\
        ${args} \\
        -O ${meta.id}.${prefix}_${variantType}.vcf.gz
    """

    stub:
    """
    touch ${meta.id}.${prefix}_${variantType}.vcf.gz
    touch ${meta.id}.${prefix}_${variantType}.vcf.gz.tbi
    """
}

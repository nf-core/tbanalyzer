process GATK_SELECT_VARIANTS_EXCLUSION {
    tag "${meta.id}"
    label 'process_medium'

    input:
        val(analysisMode)
        tuple val(meta), path(filteredVcfIndex), path(filteredVcf)
        path(intervalFile)
        path(reference)
        path("*")

    output:
        tuple val(meta), path("*.filtered_${analysisMode}_exc-rRNA.vcf.gz.tbi"), path("*.filtered_${analysisMode}_exc-rRNA.vcf.gz")

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    gatk SelectVariants --java-options "-Xmx${task.memory.giga}G" \\
        -V ${filteredVcf} \\
        --exclude-intervals ${intervalFile} \\
        ${args} \\
        -O ${meta.id}.filtered_${analysisMode}_exc-rRNA.vcf.gz
    """

    stub:
    """
    touch ${meta.id}.filtered_${analysisMode}_exc-rRNA.vcf.gz
    touch ${meta.id}.filtered_${analysisMode}_exc-rRNA.vcf.gz.tbi
    """
}

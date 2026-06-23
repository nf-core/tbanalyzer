process GATK_VARIANTS_TO_TABLE {
    tag "${meta.id}"
    label 'process_medium'

    input:
        val(prefix)
        tuple val(meta), path(vcfIndex), path(vcf)

    output:
        tuple val(meta), path("*.fa")

    when:
    task.ext.when == null || task.ext.when

    shell:
    '''
    gatk VariantsToTable --java-options "-Xmx!{task.memory.giga}G" \
        -V !{vcf} !{task.ext.args ?: ''} \
        -O !{meta.id}.!{prefix}.table

    variant_table_to_fasta.py !{meta.id}.!{prefix}.table \
        !{meta.id}.!{prefix}.fa \
        !{params.magma_cutoff_site_representation}
    '''

    stub:
    """
    touch ${meta.id}.${prefix}.fa
    """
}

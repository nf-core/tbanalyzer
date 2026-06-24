process SNPEFF {
    tag "${meta.id}"
    label 'process_medium'

    input:
        tuple val(meta), path(rawJointVariantsFile)
        path(ref_fasta)

    output:
        tuple val(meta), path("*.annotated.vcf"), emit: vcf

    when:
    task.ext.when == null || task.ext.when

    shell:
    '''
    rename_vcf_chrom.py --vcf !{rawJointVariantsFile} --source !{params.magma_ref_fasta_basename} --target 'Chromosome' \
        | snpEff !{task.ext.args ?: ''} \
        | rename_vcf_chrom.py --target !{params.magma_ref_fasta_basename} --source 'Chromosome' \
     > !{meta.id}.raw_variants.annotated.vcf
    '''

    stub:
    """
    touch ${meta.id}.raw_variants.annotated.vcf
    """
}

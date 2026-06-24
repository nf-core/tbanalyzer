process UTILS_VARIANT_TABLE_TO_FASTA {
    tag "${meta.id}"
    label 'process_low'

    input:
        tuple val(meta), path(table)

    output:
        tuple val(meta), path("*.fa"), emit: fasta

    when:
    task.ext.when == null || task.ext.when

    // Convert the GATK VariantsToTable output (variants x samples genotype table)
    // into a multi-sample FASTA alignment, with per-site representation cutoff.
    // Split out of the legacy GATK_VARIANTS_TO_TABLE module which bundled the
    // gatk + python script together; the gatk step is now the standard
    // nf-core gatk4/variantstotable module.
    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    variant_table_to_fasta.py ${table} ${prefix}.fa ${params.magma_cutoff_site_representation}
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fa
    """
}

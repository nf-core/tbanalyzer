process UTILS_REFORMAT_LOFREQ {
    tag "${meta.id}"
    label 'process_single'

    input:
        tuple val(meta), path(lofreqVcf)

    output:
        tuple val(meta), path("*lofreq.reformat.corrected.vcf")

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    reformat_lofreq.py ${lofreqVcf} \\
        ${meta.id} \\
        ${meta.id}.lofreq.reformat.vcf

    reduce_strand_bias.py \\
        ${params.magma_cutoff_strand_bias} \\
        ${meta.id}.lofreq.reformat.vcf \\
        ${meta.id}.lofreq.reformat.corrected.vcf
    """

    stub:
    """
    touch ${meta.id}.lofreq.reformat.corrected.vcf
    """
}

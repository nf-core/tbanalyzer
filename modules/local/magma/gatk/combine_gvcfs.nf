process GATK_COMBINE_GVCFS {
    tag "${joint_name}"
    label 'process_high'

    input:
        val(joint_name)
        val(gvcfs_string)
        path(gvcfs)
        path(ref_fasta)
        path(ref_exit_rif_gvcf)
        path(ref_exit_rif_gvcf_tbi)
        path("*")

    output:
        tuple val(joint_name), path("*.combined.vcf.gz.tbi"), path("*.combined.vcf.gz")

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def optionalRefExitRifGvcf = params.magma_use_ref_gvcf ? "--variant ${ref_exit_rif_gvcf}" : ""
    """
    gatk CombineGVCFs --java-options "-Xmx${task.memory.giga}G" \\
        -R ${ref_fasta} \\
        ${args} \\
        --variant ${gvcfs_string} \\
        ${optionalRefExitRifGvcf} \\
        -O ${joint_name}.combined.vcf.gz
    """

    stub:
    """
    touch ${joint_name}.combined.vcf.gz
    touch ${joint_name}.combined.vcf.gz.tbi
    """
}

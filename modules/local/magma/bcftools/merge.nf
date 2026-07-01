process BCFTOOLS_MERGE {
    label 'process_medium'

    input:
        val(joint_name)
        val(file_format)
        path(vcfs_file)      // newline-list of VCF names (used by the lofreq -l form)
        path("*")            // VCFs staged at task ROOT (matches torch-magma; -l reads bare names)

    output:
        tuple val(joint_name), path("*.vcf.gz.csi"), path("*.${file_format}.vcf.gz"), emit: vcf

    when:
    task.ext.when == null || task.ext.when

    // torch-magma uses two distinct merge modules: merge__lofreq merges from a
    // file-list (`-l <vcfs_file>`), merge__delly globs the staged files (`*.gz`).
    // Reproduce both exactly, keyed on file_format, so the emitted command
    // matches the reference per branch. (Inputs are staged at the task root, as
    // torch-magma does — the lofreq list holds bare names.)
    script:
    def mergeCmd = (file_format == 'delly')
        ? "bcftools merge *.gz -o ${joint_name}.${file_format}.vcf"
        : "bcftools merge -o ${joint_name}.${file_format}.vcf -l ${vcfs_file}"
    """
    ${mergeCmd}
    bgzip ${joint_name}.${file_format}.vcf
    bcftools index ${joint_name}.${file_format}.vcf.gz
    """

    stub:
    """
    touch ${joint_name}.${file_format}.vcf.gz
    touch ${joint_name}.${file_format}.vcf.gz.csi
    """
}

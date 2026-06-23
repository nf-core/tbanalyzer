process NTMPROFILER_COLLATE {
    label 'process_single'

    input:
        val(joint_name)
        path("results/*")

    output:
        path("*"), emit: cohort_results

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: joint_name
    """
    ntm-profiler collate \\
        -d results \\
        -o ${joint_name}.${prefix}.txt
    """

    stub:
    """
    touch ${joint_name}.ntmprofiler.collate.txt
    """
}

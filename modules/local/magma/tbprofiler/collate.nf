process TBPROFILER_COLLATE {
    tag "${joint_name}"
    label 'process_single'

    input:
        val(joint_name)
        path("results/*")
        path(resistanceDb)

    output:
        path("*"),      emit: cohort_results
        path("results"), emit: per_sample_results

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix     = task.ext.prefix ?: joint_name
    // Match torch-magma: truthiness check (empty list [] is falsy → omit --db).
    // `.name != 'NO_FILE'` produced `--db []` for an empty list, which tb-profiler rejects.
    def optionalDb = resistanceDb ? "--db ${resistanceDb}" : ""
    """
    tb-profiler collate \\
        ${optionalDb} \\
        -p ${joint_name}.${prefix} \\
        --itol
    """

    stub:
    """
    touch ${joint_name}.${prefix}.txt
    """
}

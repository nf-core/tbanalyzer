process TBPROFILER_VCF_PROFILE {
    // This consolidated module is invoked for the cohort (major-variant) path with
    // a meta MAP and for the LOFREQ/DELLY cohort-merge paths with a plain joint_name
    // STRING (from BCFTOOLS_MERGE.out). Handle both so the tag/stub never do
    // `.id` on a String (torch-magma used separate modules tagged on the name).
    // NOTE: meta is NOT referenced in the script block, so the emitted command is
    // unaffected by this — purely a label/stub robustness fix.
    tag "${meta instanceof Map ? meta.id : meta}"
    label 'process_medium'

    input:
        tuple val(meta), path(mergedVcfIndex), path(mergedVcf)
        path(resistanceDb)

    output:
        path("results/*")

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    // Match torch-magma: when no external resistance DB is supplied the callers
    // pass an empty list ([]), so use a truthiness check (an empty list is falsy)
    // → omit --db entirely and let tb-profiler use the container's built-in tbdb.
    // The previous `.name != 'NO_FILE'` test produced `--db []` for an empty list
    // (`[].name` == []), which tb-profiler rejects ("Can't find the database []").
    def optionalDb = resistanceDb ? "--db ${resistanceDb.name}" : ""
    """
    bcftools view ${mergedVcf} | sed 's/${params.magma_ref_fasta_basename}/Chromosome/g' > intermediate.vcf

    cat intermediate.vcf | bcftools view -Oz -o intermediate.vcf.gz

    tb-profiler profile \\
        ${optionalDb} \\
        --threads ${task.cpus} \\
        --vcf intermediate.vcf.gz \\
        ${args}
    """

    stub:
    """
    mkdir results
    touch results/${meta instanceof Map ? meta.id : meta}.results.json
    """
}

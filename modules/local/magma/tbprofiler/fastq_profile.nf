process TBPROFILER_FASTQ_PROFILE {
    tag "${meta.id}"
    label 'process_medium'

    input:
        tuple val(meta), path(reads)

    output:
        tuple val(meta), path("results/*.json"), emit: json
        tuple val(meta), path("results/*.csv"), emit: csv, optional: true
        tuple val(meta), path("results/*.txt"), emit: txt, optional: true

    when:
    task.ext.when == null || task.ext.when

    script:
    def args       = task.ext.args   ?: ''
    def prefix     = task.ext.prefix ?: "${meta.id}"
    def input_reads = meta.single_end ? "--read1 ${reads}" : "--read1 ${reads[0]} --read2 ${reads[1]}"
    """
    tb-profiler profile \\
        ${args} \\
        --prefix ${prefix} \\
        --threads ${task.cpus} \\
        ${input_reads}
    """

    stub:
    """
    mkdir results
    touch results/${meta.id}.results.json
    """
}

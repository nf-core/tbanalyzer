process RDANALYZER {
    tag "${meta.id}"
    label 'process_low'

    input:
        tuple val(meta), path(reads)
        path(ref_fasta_rdanalyzer)

    output:
        tuple path("${meta.id}.result"), path("${meta.id}.depth"), emit: result

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    RD-Analyzer-extended.py ${ref_fasta_rdanalyzer} -o ${meta.id} ${reads} ${args}
    """

    stub:
    """
    touch ${meta.id}.result
    touch ${meta.id}.depth
    """
}

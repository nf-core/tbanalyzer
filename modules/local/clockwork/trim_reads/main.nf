process TRIM_READS {
    tag "${meta.id}"
    label 'process_low'
    container 'ghcr.io/iqbal-lab-org/clockwork:v0.12.5'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("trimmed_reads_dir"), emit: trimmed
    path "versions.yml",                        emit: versions

    script:
    // Faithful to upstream variant_call.nf: clockwork trim_reads <outprefix> <r1> <r2>
    """
    mkdir trimmed_reads_dir
    clockwork trim_reads trimmed_reads_dir/reads ${reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        clockwork: \$(clockwork version 2>&1 | tail -n1)
    END_VERSIONS
    """

    stub:
    """
    mkdir trimmed_reads_dir
    touch trimmed_reads_dir/reads.1.1.fq trimmed_reads_dir/reads.1.2.fq
    touch versions.yml
    """
}

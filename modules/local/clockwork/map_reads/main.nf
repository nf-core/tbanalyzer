process MAP_READS {
    tag "${meta.id}"
    label 'process_medium'
    container 'ghcr.io/iqbal-lab-org/clockwork:v0.12.5'

    input:
    tuple val(meta), path("trimmed_reads_dir")
    path ref_dir

    output:
    tuple val(meta), path("rmdup.bam"), emit: bam
    path "versions.yml",                emit: versions

    script:
    // Faithful to upstream: clockwork map_reads <sample> ref.fa rmdup.bam <sorted trimmed reads>
    """
    reads_string=\$(ls trimmed_reads_dir/reads*fq | sort)
    clockwork map_reads ${meta.id} ${ref_dir}/ref.fa rmdup.bam \$reads_string

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        clockwork: \$(clockwork version 2>&1 | tail -n1)
    END_VERSIONS
    """

    stub:
    """
    touch rmdup.bam versions.yml
    """
}

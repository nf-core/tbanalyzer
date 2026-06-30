process CALL_VARS_CORTEX {
    tag "${meta.id}"
    label 'process_high'
    container 'ghcr.io/iqbal-lab-org/clockwork:v0.12.5'

    input:
    tuple val(meta), path("rmdup.bam")
    path ref_dir
    val mem_height

    output:
    tuple val(meta), path("cortex"), emit: cortex_dir
    path "versions.yml",             emit: versions

    script:
    // Faithful to upstream: clockwork cortex --mem_height N <ref_dir> rmdup.bam cortex <sample>
    """
    clockwork cortex --mem_height ${mem_height} ${ref_dir} rmdup.bam cortex ${meta.id}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        clockwork: \$(clockwork version 2>&1 | tail -n1)
    END_VERSIONS
    """

    stub:
    """
    mkdir -p cortex/cortex.out/vcfs
    touch cortex/cortex.out/vcfs/sample_FINAL_raw.vcf versions.yml
    """
}

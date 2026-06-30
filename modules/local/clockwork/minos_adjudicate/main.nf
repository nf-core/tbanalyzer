process MINOS_ADJUDICATE {
    tag "${meta.id}"
    label 'process_medium'
    container 'ghcr.io/iqbal-lab-org/clockwork:v0.12.5'

    input:
    tuple val(meta), path("samtools.vcf"), path("rmdup.bam"), path("rmdup.bam.bai"), path("cortex")
    path ref_dir

    output:
    tuple val(meta), path("minos/final.vcf"), emit: vcf
    path "minos",                             emit: minos_dir
    path "versions.yml",                      emit: versions

    script:
    // Faithful to upstream: minos adjudicate --force --reads rmdup.bam minos ref.fa samtools.vcf <cortex FINAL raw vcf>
    """
    cortex_vcf=\$(find cortex/cortex.out/vcfs/ -name "*FINAL*raw.vcf" | head -n1)
    minos adjudicate --force --reads rmdup.bam minos ${ref_dir}/ref.fa samtools.vcf \$cortex_vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minos: \$(minos --version 2>&1 | tail -n1)
    END_VERSIONS
    """

    stub:
    """
    mkdir minos
    touch minos/final.vcf versions.yml
    """
}

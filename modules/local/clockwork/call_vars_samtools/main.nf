process CALL_VARS_SAMTOOLS {
    tag "${meta.id}"
    label 'process_medium'
    container 'ghcr.io/iqbal-lab-org/clockwork:v0.12.5'

    input:
    tuple val(meta), path("rmdup.bam")
    path ref_dir

    output:
    tuple val(meta), path("samtools.vcf"), path("rmdup.bam"), path("rmdup.bam.bai"), emit: calls
    path "versions.yml",                                                             emit: versions

    script:
    // Faithful to upstream: bcftools mpileup -f ref.fa rmdup.bam | bcftools call -vm -O v -o samtools.vcf
    """
    bcftools mpileup --output-type u -f ${ref_dir}/ref.fa rmdup.bam | bcftools call -vm -O v -o samtools.vcf
    samtools index rmdup.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -n1 | sed 's/bcftools //')
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
    END_VERSIONS
    """

    stub:
    """
    touch samtools.vcf rmdup.bam.bai versions.yml
    """
}

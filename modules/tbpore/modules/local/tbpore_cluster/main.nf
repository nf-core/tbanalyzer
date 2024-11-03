process TBPORE_CLUSTER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/tbpore:0.7.1--pyhdfd78af_0':
        'biocontainers/tbpore:0.7.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(consensus_fa)

    output:

    tuple val(meta), path("*.txt"), emit: txt
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    tbpore cluster $args \\
        --threads $task.cpus \\
        $consensus_fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tbpore: \$(tbpore --version |& sed s/tbpore, version //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tbpore: \$(tbpore --version |& sed s/tbpore, version //')
    END_VERSIONS
    """
}


process TBPORE_PROCESS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/tbpore:0.7.1--pyhdfd78af_0':
        'biocontainers/tbpore:0.7.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fastq)
    path db

    output:
    tuple val(meta), path("*.json"), emit: json
    tuple val(meta), path("*.fa")  , emit: fa
    tuple val(meta), path("*.bcf") , emit: bcf
    tuple val(meta), path("*.txt") , emit: txt
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    tbpore process $args \\
        --threads $task.cpus \\
        --name $prefix \\
        --db $db \\
        $fastq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tbpore: \$(tbpore --version |& sed s/tbpore, version //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // TODO nf-core: A stub section should mimic the execution of the original module as best as possible
    //               Have a look at the following examples:
    //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    """
    touch ${prefix}.json
    touch ${prefix}.fa
    touch ${prefix}.bcf
    touch ${prefix}.txt


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tbpore:  \$(tbpore --version |& sed s/tbpore, version //')
    END_VERSIONS
    """
}

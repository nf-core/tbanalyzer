process IQTREE {
    tag "${meta.id}"
    label 'process_high'
    label 'process_long'

    input:
        val(prefix)
        tuple val(meta), path(fasta)

    output:
        tuple val(meta), path("${meta.id}.${prefix}.treefile"), emit: tree_tuple
        path("${meta.id}.${prefix}.bionj")
        path("${meta.id}.${prefix}.ckp.gz")
        path("${meta.id}.${prefix}.iqtree")
        path("${meta.id}.${prefix}.log")
        path("${meta.id}.${prefix}.mldist")
        path("${meta.id}.${prefix}.model.gz")
        path("${meta.id}.${prefix}.treefile")

    when:
    task.ext.when == null || task.ext.when

    script:
    if (params.magma_iqtree_standard_bootstrap) {
        arguments = '-b 1000'
    } else if (params.magma_iqtree_fast_ml_only) {
        arguments = '-fast'
    } else if (params.magma_iqtree_fast_bootstrapped_phylogeny) {
        arguments = '-bb 1000 -alrt 1000'
    } else if (params.magma_iqtree_accurate_ml_only) {
        arguments = '-allnni'
    } else {
        arguments = '-allnni'
    }
    """
    iqtree \\
        -s ${fasta} \\
        -T AUTO \\
        ${arguments} \\
        --prefix ${meta.id}.${prefix}
    """

    stub:
    """
    touch ${meta.id}.${prefix}.bionj
    touch ${meta.id}.${prefix}.ckp.gz
    touch ${meta.id}.${prefix}.iqtree
    touch ${meta.id}.${prefix}.log
    touch ${meta.id}.${prefix}.mldist
    touch ${meta.id}.${prefix}.model.gz
    touch ${meta.id}.${prefix}.treefile
    """
}

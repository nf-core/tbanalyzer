process CLUSTERPICKER {
    tag "snpCount: ${snpCount}"
    label 'process_medium'

    input:
        tuple val(meta), path(fasta), path(newickTree)
        val(snpCount)
        val(prefix)

    output:
        tuple val(meta), path("*${snpCount}SNPcluster*"), emit: clusters

    when:
    task.ext.when == null || task.ext.when

    shell:
    '''
    cp !{fasta} !{fasta.getBaseName()}.!{snpCount}SNPcluster.fa
    cp !{newickTree} !{newickTree.getBaseName()}.!{snpCount}SNPcluster.treefile

    FRACTION=$(echo !{snpCount}/$(cat !{fasta} | head -n 2 | tail -n 1 | wc -c) | bc -l)
    jvm_mem_opts="-Xmx!{task.memory.giga}G"

    cluster-picker \\
        !{fasta} \\
        !{newickTree} \\
        0 \\
        0 \\
        $FRACTION \\
        0 \\
        gap

    cp !{meta.id}.!{prefix}_clusterPicks_log.txt !{meta.id}.!{prefix}_!{snpCount}SNPclusterPicks_log.txt
    cp !{meta.id}.!{prefix}_clusterPicks.nwk !{meta.id}.!{prefix}_!{snpCount}SNPclusterPicks.nwk
    cp !{meta.id}.!{prefix}_clusterPicks.nwk.figTree !{meta.id}.!{prefix}_!{snpCount}SNPclusterPicks.nwk.figTree
    cp !{meta.id}.variable.!{prefix}.fa_!{meta.id}.!{prefix}_clusterPicks.fas !{meta.id}.variable.!{prefix}.fa_!{meta.id}.!{prefix}_!{snpCount}SNPclusterPicks.fas
    '''

    stub:
    """
    touch ${meta.id}.${snpCount}SNPcluster.txt
    """
}

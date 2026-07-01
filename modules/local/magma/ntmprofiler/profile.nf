process NTMPROFILER_PROFILE {
    tag "${meta.id}"
    label 'process_medium'

    input:
        tuple val(meta), path(sampleReads)

    output:
        path("results/*txt"), emit: profile_txt
        path("results/*json"), emit: profile_json

    when:
    task.ext.when == null || task.ext.when

    script:
    if (meta.paired) {
        """
        ntm-profiler profile \\
            -1 ${sampleReads[0]} \\
            -2 ${sampleReads[1]} \\
            -p ${meta.id} \\
            -d results \\
            --txt
        """
    } else {
        """
        ntm-profiler profile \\
            -1 ${sampleReads[0]} \\
            -p ${meta.id} \\
            -d results \\
            --txt
        """
    }

    stub:
    """
    mkdir -p results
    touch results/${meta.id}.txt
    touch results/${meta.id}.json
    """
}

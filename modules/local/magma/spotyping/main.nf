process SPOTYPING {
    tag "${meta.id}"
    label 'process_low'

    input:
        tuple val(meta), path(reads)

    output:
        path("*.patched.txt"), emit: txt
        path("SITVIT*.xls"),   emit: xls, optional: true

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    SpoTyping.py ${reads} --output ${meta.id}.txt ${args}
    awk '{print "${meta.id}\t" \$0}' ${meta.id}.txt > ${meta.id}.patched.txt
    """

    stub:
    """
    touch ${meta.id}.patched.txt
    """
}

process UTILS_ELIMINATE_ANNOTATION {
    tag "${meta.id}"
    label 'process_single'

    input:
        val(analysisType)
        tuple val(meta), path(annotationsLog), path(tranchesFile)

    output:
        path("*annotations.txt"),                                    emit: reducedAnnotationsFile
        tuple val(meta), path("*annotations_tranches.json"),         emit: annotationsTranchesFile

    when:
    task.ext.when == null || task.ext.when

    script:
    def annotationPrefix = task.ext.prefix ?: ''
    """
    reduce_annotations.py \\
        --input ${annotationsLog} \\
        --output ${meta.id}.${analysisType}.${annotationPrefix}.annotations.txt \\
        --tranches ${tranchesFile} \\
        --output_tranches_and_annotations ${meta.id}.${analysisType}.${annotationPrefix}.annotations_tranches.json
    """

    stub:
    """
    touch ${meta.id}.${analysisType}.${annotationPrefix}.annotations.txt
    touch ${meta.id}.${analysisType}.${annotationPrefix}.annotations_tranches.json
    """
}

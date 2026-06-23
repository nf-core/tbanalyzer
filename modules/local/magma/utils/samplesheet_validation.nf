process SAMPLESHEET_VALIDATION {
    errorStrategy 'terminate'

    input:
        path(samplesheet)

    output:
        val true,                           emit: status
        path("magma_samplesheet.json"),     emit: validated_samplesheet

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    samplesheet_validation.py ${samplesheet} samplesheet.format_valid.csv
    """

    stub:
    """
    touch magma_samplesheet.json
    """
}

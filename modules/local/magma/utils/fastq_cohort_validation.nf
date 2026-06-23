process UTILS_FASTQ_COHORT_VALIDATION {
    label 'process_single'

    input:
        path("fastq_reports/*")
        path(magma_validated_samplesheet_json)

    output:
        path("magma_analysis.json"), emit: magma_analysis_json

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    csvtk concat fastq_reports/* | csvtk csv2json -k file > merged_fastq_reports.json

    fastq_cohort_validation.py ${magma_validated_samplesheet_json} merged_fastq_reports.json magma_analysis.json

    rm merged_fastq_reports.json
    """

    stub:
    """
    touch magma_analysis.json
    """
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE_FASTQS_WF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Per-FASTQ validation + cohort-level QC cutoffs. Mirrors torch-magma's
    workflows/validate_fastqs_wf.nf.
*/

include { FASTQ_VALIDATOR              } from '../../../modules/local/magma/fastqvalidator/main'
include { UTILS_FASTQ_COHORT_VALIDATION } from '../../../modules/local/magma/utils/fastq_cohort_validation'


workflow VALIDATE_FASTQS_WF {

    take:
    validated_samplesheet_ch   // channel: validated samplesheet JSON (from SAMPLESHEET_VALIDATION)
    samplesheet_status_ch      // channel: status flag (passes through to FASTQ_VALIDATOR)

    main:

    // Build a per-FASTQ-file channel from the validated JSON
    fastqs_ch = validated_samplesheet_ch
        .splitJson()
        .map { row ->
            def meta = [
                id:             row.magma_sample_name,
                bam_rg_string:  row.magma_bam_rg_string,
                paired:         row.R2 ? true : false,
                single_end:     row.R2 ? false : true
            ]
            row.R2 ? [ meta, [row.R1, row.R2] ] : [ meta, [row.R1] ]
        }
        .transpose()   // emit one record per fastq file

    // Validate each FASTQ individually
    FASTQ_VALIDATOR(fastqs_ch, samplesheet_status_ch)

    // Cohort-level validation (QC cutoffs, contamination check)
    UTILS_FASTQ_COHORT_VALIDATION(
        FASTQ_VALIDATOR.out.fastq_report.collect(),
        validated_samplesheet_ch
    )

    // Build approved-samples channel from magma_analysis.json
    approved_fastqs_ch = UTILS_FASTQ_COHORT_VALIDATION.out.magma_analysis_json
        .splitJson()
        .filter { it.value.fastqs_approved }
        .map { row ->
            def meta = [
                id:            row.value.magma_sample_name,
                bam_rg_string: row.value.magma_bam_rg_string,
                paired:        row.value.R2 ? true : false,
                single_end:    row.value.R2 ? false : true
            ]
            row.value.R2 ? [ meta, [row.value.R1, row.value.R2] ] : [ meta, [row.value.R1] ]
        }

    emit:
    approved_fastqs_ch
}

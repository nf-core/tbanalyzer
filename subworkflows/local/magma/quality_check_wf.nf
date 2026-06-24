/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    QUALITY_CHECK_WF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Per-sample FASTQ QC: FastQC + (optionally) NTM/TB-profiler / SpoTyping.
    Mirrors torch-magma's workflows/quality_check_wf.nf.
*/

include { FASTQC                                          } from '../../../modules/local/magma/nf-core/fastqc/main'
include { NTMPROFILER_PROFILE                             } from '../../../modules/local/magma/ntmprofiler/profile'
include { NTMPROFILER_COLLATE                             } from '../../../modules/local/magma/ntmprofiler/collate'
include { TBPROFILER_FASTQ_PROFILE                        } from '../../../modules/local/magma/tbprofiler/fastq_profile'
include { TBPROFILER_COLLATE as TBPROFILER_FASTQ_COLLATE } from '../../../modules/local/magma/tbprofiler/collate'
include { SPOTYPING                                       } from '../../../modules/local/magma/spotyping/main'
include { UTILS_CAT_SPOTYPING                             } from '../../../modules/local/magma/utils/cat_spotyping'


workflow QUALITY_CHECK_WF {

    take:
    approved_fastqs_ch   // channel: [ meta, [fastqs] ]

    main:

    FASTQC(approved_fastqs_ch)

    if (!params.magma_skip_ntmprofiler) {
        NTMPROFILER_PROFILE(approved_fastqs_ch)
        NTMPROFILER_COLLATE(params.magma_vcf_name, NTMPROFILER_PROFILE.out.profile_json.collect())
    }

    if (!params.magma_skip_tbprofiler_fastq) {
        TBPROFILER_FASTQ_PROFILE(approved_fastqs_ch)
        TBPROFILER_FASTQ_COLLATE(
            params.magma_vcf_name,
            TBPROFILER_FASTQ_PROFILE.out.json.map { _meta, j -> j }.collect(),
            []
        )
    }

    if (!params.magma_skip_spotyping) {
        SPOTYPING(approved_fastqs_ch)
        UTILS_CAT_SPOTYPING(SPOTYPING.out.txt.collect())
    }

    emit:
    // FASTQC zips for the cohort MultiQC. Map drops the meta map; downstream
    // REPORTS_WF only needs the bare paths.
    reports_fastqc_ch = FASTQC.out.zip.map { _meta, file -> file }
}

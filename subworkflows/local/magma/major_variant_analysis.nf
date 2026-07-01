include { TBPROFILER_VCF_PROFILE as TBPROFILER_VCF_PROFILE_COHORT } from '../../../modules/local/magma/tbprofiler/vcf_profile'
include { TBPROFILER_COLLATE as TBPROFILER_COLLATE_COHORT         } from '../../../modules/local/magma/tbprofiler/collate'


workflow MAJOR_VARIANT_ANALYSIS {

    take:
    merged_vcf_ch              // channel: [ meta, tbi, vcf ]
    reformatted_lofreq_vcf_ch  // channel: (not used directly here, passed for future use)

    main:

    def resistanceDb = []

    TBPROFILER_VCF_PROFILE_COHORT(merged_vcf_ch, resistanceDb)

    TBPROFILER_COLLATE_COHORT(
        params.magma_vcf_name,
        TBPROFILER_VCF_PROFILE_COHORT.out.collect(),
        resistanceDb
    )

    emit:
    major_variants_results_ch = TBPROFILER_COLLATE_COHORT.out.per_sample_results
}

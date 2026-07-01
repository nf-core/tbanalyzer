/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MINOR_VARIANTS_ANALYSIS_WF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Cohort merge of per-sample LoFreq VCFs + TBprofiler resistance profile.
    Mirrors torch-magma's workflows/minor_variants_analysis_wf.nf.
*/

include { BCFTOOLS_MERGE as BCFTOOLS_MERGE_LOFREQ } from '../../../modules/local/magma/bcftools/merge'
include { TBPROFILER_VCF_PROFILE as TBPROFILER_VCF_PROFILE_LOFREQ } from '../../../modules/local/magma/tbprofiler/vcf_profile'
include { TBPROFILER_COLLATE     as TBPROFILER_COLLATE_LOFREQ      } from '../../../modules/local/magma/tbprofiler/collate'
include { UTILS_MULTIPLE_INFECTION_FILTER } from '../../../modules/local/magma/utils/multiple_infection_filter'


workflow MINOR_VARIANTS_ANALYSIS_WF {

    take:
    reformatted_lofreq_vcfs_tuple_ch   // channel: collected [tbi, vcf] pairs
    outdir                              // val: output dir (for the vcf-list file)

    main:

    def vcfs_file = reformatted_lofreq_vcfs_tuple_ch
        .flatten()
        .filter { it instanceof java.nio.file.Path && it.getExtension() == "gz" }
        .map { it.name }
        .collectFile(name: "${outdir}/minor_variant_vcfs.txt", newLine: true)

    BCFTOOLS_MERGE_LOFREQ(
        params.magma_vcf_name,
        'lofreq',
        vcfs_file,
        reformatted_lofreq_vcfs_tuple_ch
            .flatten()
            .filter { it instanceof java.nio.file.Path }
            .collect()
    )

    def resistanceDb = []
    TBPROFILER_VCF_PROFILE_LOFREQ(BCFTOOLS_MERGE_LOFREQ.out, resistanceDb)
    TBPROFILER_COLLATE_LOFREQ(
        params.magma_vcf_name,
        TBPROFILER_VCF_PROFILE_LOFREQ.out.collect(),
        resistanceDb
    )
    UTILS_MULTIPLE_INFECTION_FILTER(TBPROFILER_COLLATE_LOFREQ.out.per_sample_results)

    emit:
    approved_samples_ch        = UTILS_MULTIPLE_INFECTION_FILTER.out.approved_samples
    rejected_samples_ch        = UTILS_MULTIPLE_INFECTION_FILTER.out.rejected_samples
    minor_variants_results_ch  = TBPROFILER_COLLATE_LOFREQ.out.per_sample_results
}

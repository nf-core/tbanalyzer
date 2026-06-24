/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MERGE_WF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Cohort joint genotyping + phylogeny + clustering.  Mirrors torch-magma's
    workflows/merge_wf.nf.

    Stages:
      - filter to approved samples (joins approved_samples_ch against the
        collated GVCFs)
      - PREPARE_COHORT_VCF (combine + genotype + snpeff + bgzip + index)
      - SNP_ANALYSIS (VQSR + rRNA exclusion)
      - INDEL_ANALYSIS (select-variants + rRNA exclusion)
      - GATK_MERGE_VCFS_INC (combine the rRNA-included SNP + INDEL VCFs)
      - MAJOR_VARIANT_ANALYSIS (TBprofiler cohort)
      - PHYLOGENY_ANALYSIS_EXCOMPLEX / INCCOMPLEX
      - CLUSTER_ANALYSIS_EXCOMPLEX / INCCOMPLEX
*/

include { PREPARE_COHORT_VCF                                  } from './prepare_cohort_vcf'
include { SNP_ANALYSIS                                        } from './snp_analysis'
include { INDEL_ANALYSIS                                      } from './indel_analysis'
include { MAJOR_VARIANT_ANALYSIS                              } from './major_variant_analysis'
include { PHYLOGENY_ANALYSIS as PHYLOGENY_ANALYSIS_INCCOMPLEX } from './phylogeny_analysis'
include { PHYLOGENY_ANALYSIS as PHYLOGENY_ANALYSIS_EXCOMPLEX  } from './phylogeny_analysis'
include { CLUSTER_ANALYSIS   as CLUSTER_ANALYSIS_INCCOMPLEX   } from './cluster_analysis'
include { CLUSTER_ANALYSIS   as CLUSTER_ANALYSIS_EXCOMPLEX    } from './cluster_analysis'
include { GATK4_MERGEVCFS as GATK_MERGE_VCFS_INC              } from '../../../modules/local/magma/nf-core/gatk4/mergevcfs/main'


workflow MERGE_WF {

    take:
    gvcf_tbi_ch                       // channel: per-sample GVCF tbi from CALL_WF
    gvcf_vcf_ch                       // channel: per-sample GVCF vcf from CALL_WF
    reformatted_lofreq_vcfs_tuple_ch  // channel: collected [tbi, vcf] pairs (LoFreq)
    approved_samples_ch               // channel: [sample_name] (passed cohort QC)

    main:

    // Build gvcf channel keyed on the sample name so it can join the
    // approved-samples channel (which carries sample-name Strings).
    def collated_gvcfs_ch = gvcf_tbi_ch
        .join(gvcf_vcf_ch)
        .collect()
        .flatten()
        .collate(3)
        .map { meta, tbi, vcf -> [ meta.id, tbi, vcf ] }

    // Filter to approved samples only
    def selected_gvcfs_ch = collated_gvcfs_ch
        .join(approved_samples_ch.map { [it[0], it[0]] })
        .flatten()
        .filter { it instanceof java.nio.file.Path }
        .collect()

    PREPARE_COHORT_VCF(selected_gvcfs_ch)

    SNP_ANALYSIS(PREPARE_COHORT_VCF.out.cohort_vcf_and_index_ch)
    INDEL_ANALYSIS(PREPARE_COHORT_VCF.out.cohort_vcf_and_index_ch)

    def merge_inc_vcf_ch = SNP_ANALYSIS.out.snp_inc_vcf_ch
        .join(INDEL_ANALYSIS.out.indel_vcf_ch)
        .map { meta, _snp_tbi, snp_vcf, _indel_tbi, indel_vcf -> [ meta, [ snp_vcf, indel_vcf ] ] }

    GATK_MERGE_VCFS_INC(merge_inc_vcf_ch, Channel.value([ [id: 'none'], [] ]))

    def merge_inc_vcf_out_ch = GATK_MERGE_VCFS_INC.out.tbi.join(GATK_MERGE_VCFS_INC.out.vcf)

    MAJOR_VARIANT_ANALYSIS(merge_inc_vcf_out_ch, reformatted_lofreq_vcfs_tuple_ch)

    // ExComplex phylogeny (excludes DR loci + complex/repetitive regions)
    def excomplex_exclude_interval_ref_ch = Channel.of(
        file(params.magma_coll2018_vcf),
        file(params.magma_coll2018_vcf_tbi),
        file(params.magma_excluded_loci_list)
    ).flatten()

    def excomplex_snp_dists_ch = Channel.empty()
    if (!params.magma_skip_phylogeny_and_clustering) {
        PHYLOGENY_ANALYSIS_EXCOMPLEX(
            Channel.value('ExDR.ExComplex'),
            excomplex_exclude_interval_ref_ch,
            SNP_ANALYSIS.out.snp_exc_vcf_ch
        )

        CLUSTER_ANALYSIS_EXCOMPLEX(
            PHYLOGENY_ANALYSIS_EXCOMPLEX.out.snpsites_tree_tuple,
            Channel.value('ExDR.ExComplex')
        )

        excomplex_snp_dists_ch = PHYLOGENY_ANALYSIS_EXCOMPLEX.out.snp_dists_ch
    }

    // IncComplex phylogeny (excludes DR loci only)
    if (!params.magma_skip_complex_regions && !params.magma_skip_phylogeny_and_clustering) {
        def inccomplex_exclude_interval_ref_ch = Channel.of(
            file(params.magma_coll2018_vcf),
            file(params.magma_coll2018_vcf_tbi)
        ).flatten()

        PHYLOGENY_ANALYSIS_INCCOMPLEX(
            Channel.value('ExDR.IncComplex'),
            inccomplex_exclude_interval_ref_ch,
            SNP_ANALYSIS.out.snp_exc_vcf_ch
        )

        CLUSTER_ANALYSIS_INCCOMPLEX(
            PHYLOGENY_ANALYSIS_INCCOMPLEX.out.snpsites_tree_tuple,
            Channel.value('ExDR.IncComplex')
        )
    }

    emit:
    major_variants_results_ch = MAJOR_VARIANT_ANALYSIS.out.major_variants_results_ch
    snp_dists_ch              = excomplex_snp_dists_ch
}

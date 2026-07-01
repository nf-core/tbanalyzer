include { GATK4_SELECTVARIANTS as GATK_SELECT_VARIANTS_INDEL             } from '../../../modules/local/magma/nf-core/gatk4/selectvariants/main'
include { GATK4_SELECTVARIANTS as GATK_SELECT_VARIANTS_EXCLUSION_INDEL } from '../../../modules/local/magma/nf-core/gatk4/selectvariants/main'


// NOTE: Full INDEL VQSR is experimental (XBS_merge#L164) and disabled by default.
//       The indel_vcf_ch emits the raw selected INDELs (no VQSR applied).
workflow INDEL_ANALYSIS {

    take:
    cohort_vcf_and_index_ch   // channel: [ meta, tbi, vcf ]

    main:

    // Select INDEL/MNP/MIXED variants from the joint VCF.
    // Local positional inputs collapse to nf-core's single tuple input:
    // 'INDEL', 'raw', the ext.args go into conf/modules.config; ext.prefix
    // controls the output filename.
    def select_indel_input_ch = cohort_vcf_and_index_ch.map { meta, tbi, vcf -> [ meta, vcf, tbi, [] ] }
    GATK_SELECT_VARIANTS_INDEL(select_indel_input_ch)

    // Rebuild the [meta, tbi, vcf] 3-tuple downstream consumers expect from
    // nf-core's separate vcf / tbi emits.
    def select_indel_vcftuple_ch = GATK_SELECT_VARIANTS_INDEL.out.tbi.join(GATK_SELECT_VARIANTS_INDEL.out.vcf)

    // Exclude rRNA loci from indel VCF. Uses the patched nf-core gatk4/selectvariants
    // with ext.intervals_mode = 'exclude' (see conf/modules.config).
    def exclude_indel_input_ch = select_indel_vcftuple_ch.map { meta, tbi, vcf -> [ meta, vcf, tbi, file(params.magma_rrna_list) ] }
    GATK_SELECT_VARIANTS_EXCLUSION_INDEL(exclude_indel_input_ch)
    def exclude_indel_vcftuple_ch = GATK_SELECT_VARIANTS_EXCLUSION_INDEL.out.tbi.join(GATK_SELECT_VARIANTS_EXCLUSION_INDEL.out.vcf)

    emit:
    // NOTE: returns raw selected INDELs (VQSR deferred to future work)
    indel_vcf_ch     = select_indel_vcftuple_ch
    indel_exc_vcf_ch = exclude_indel_vcftuple_ch
}

include { GATK4_SELECTVARIANTS as GATK_SELECT_VARIANTS_SNP             } from '../../../modules/local/magma/nf-core/gatk4/selectvariants/main'
include { GATK_VARIANT_RECALIBRATOR as GATK_VARIANT_RECALIBRATOR_SNP   } from '../../../modules/local/magma/gatk/variant_recalibrator'
include { GATK4_APPLYVQSR as GATK_APPLY_VQSR_SNP                       } from '../../../modules/local/magma/nf-core/gatk4/applyvqsr/main'
include { GATK4_SELECTVARIANTS as GATK_SELECT_VARIANTS_EXCLUSION_SNP } from '../../../modules/local/magma/nf-core/gatk4/selectvariants/main'
include { OPTIMIZE_VARIANT_RECALIBRATION } from './optimize_variant_recalibration'


workflow SNP_ANALYSIS {

    take:
    cohort_vcf_and_index_ch   // channel: [ meta, tbi, vcf ]

    main:

    // Select SNP variants from the joint VCF.
    // Local input shape (8 positional params) collapses to nf-core's single
    // tuple input. variantType, prefix, and the --select-type-to-include flag
    // all move into ext.args / ext.prefix in conf/modules.config.
    def select_snp_input_ch = cohort_vcf_and_index_ch.map { meta, tbi, vcf -> [ meta, vcf, tbi, [] ] }
    GATK_SELECT_VARIANTS_SNP(select_snp_input_ch)

    // Build resource file channels for VQSR
    arg_files_ch = Channel.of(
            ["coll2014,known=false,training=true,truth=true,prior=15.0",  file(params.magma_coll2014_vcf),   file(params.magma_coll2014_vcf_tbi)],
            ["coll2018,known=false,training=true,truth=true,prior=15.0",  file(params.magma_coll2018_vcf),   file(params.magma_coll2018_vcf_tbi)],
            ["Napier2020,known=false,training=true,truth=true,prior=15.0",file(params.magma_napier2020_vcf), file(params.magma_napier2020_vcf_tbi)],
            ["Benavente2015,known=true,training=false,truth=false,prior=5.0",file(params.magma_benavente2015_vcf),file(params.magma_benavente2015_vcf_tbi)]
        )
        .ifEmpty([])
        .map { row -> row != [] ? [ "${row[0]} ${row[1].getName()}", row[1], row[2] ] : [] }
        .flatten()

    args_ch = arg_files_ch
        .filter { it instanceof String || it instanceof org.codehaus.groovy.runtime.GStringImpl }
        .reduce { a, b -> "$a --resource:$b" }
        .ifEmpty('')

    resources_files_ch = arg_files_ch
        .filter { it instanceof java.nio.file.Path && it.getExtension() == "gz" }
        .collect()
        .ifEmpty([])

    resources_file_indexes_ch = arg_files_ch
        .filter { it instanceof java.nio.file.Path && it.getExtension() == "tbi" }
        .collect()
        .ifEmpty([])

    // Rebuild the [meta, tbi, vcf] tuple that downstream local subworkflows
    // (OPTIMIZE_VARIANT_RECALIBRATION, the still-local GATK_VARIANT_RECALIBRATOR_SNP)
    // expect. nf-core SelectVariants emits .vcf and .tbi as separate channels.
    def select_snp_vcftuple_ch = GATK_SELECT_VARIANTS_SNP.out.tbi.join(GATK_SELECT_VARIANTS_SNP.out.vcf)

    if (!params.magma_skip_variant_recalibration) {

        // Optimized VQSR: try 6 annotation combinations and pick the best
        OPTIMIZE_VARIANT_RECALIBRATION(
            'SNP',
            select_snp_vcftuple_ch,
            args_ch,
            resources_files_ch,
            resources_file_indexes_ch
        )

        vqsr_ch = OPTIMIZE_VARIANT_RECALIBRATION.out.optimized_vqsr_ch

    } else {

        // Simple VQSR with default annotations
        GATK_VARIANT_RECALIBRATOR_SNP(
            'SNP',
            '-an DP -an AS_MQ',
            select_snp_vcftuple_ch,
            args_ch,
            resources_files_ch,
            resources_file_indexes_ch,
            params.magma_ref_fasta,
            [params.magma_ref_fasta_fai, params.magma_ref_fasta_dict]
        )

        vqsr_ch = select_snp_vcftuple_ch
            .join(GATK_VARIANT_RECALIBRATOR_SNP.out.recalVcfTuple)
            .join(GATK_VARIANT_RECALIBRATOR_SNP.out.tranchesFile)
    }

    // Migration: GATK_APPLY_VQSR is now the standard nf-core gatk4/applyvqsr.
    //   Local input: 'SNP', [meta, tbi, vcf, recalTbi, recalVcf, tranches],
    //                ref_fasta, [ref_fasta_fai, ref_fasta_dict]
    //   nf-core    : [meta, vcf, vcf_tbi, recal, recal_index, tranches],
    //                fasta, fai, dict  (note tuple element order swapped:
    //                vcf is index 1 not 2, recal at index 3, recal_index at 4)
    // The 'SNP' analysisMode val is moved into ext.args (-mode SNP) in
    // conf/modules.config; the output filename suffix is preserved via ext.prefix.
    def apply_vqsr_input_ch = vqsr_ch.map { meta, tbi, vcf, recalTbi, recalVcf, tranches ->
        [ meta, vcf, tbi, recalVcf, recalTbi, tranches ]
    }
    GATK_APPLY_VQSR_SNP(
        apply_vqsr_input_ch,
        file(params.magma_ref_fasta),
        file(params.magma_ref_fasta_fai),
        file(params.magma_ref_fasta_dict)
    )

    // Downstream consumers used the local `filteredVcfTuple` emit shape [meta, tbi, vcf].
    // nf-core gatk4/applyvqsr emits vcf / tbi separately; recompose with .join.
    def apply_vqsr_snp_filtered_ch = GATK_APPLY_VQSR_SNP.out.tbi.join(GATK_APPLY_VQSR_SNP.out.vcf)

    // Exclude rRNA loci. Uses the patched nf-core gatk4/selectvariants module
    // with ext.intervals_mode = 'exclude' (see conf/modules.config) so the
    // module's interval slot emits `--exclude-intervals` instead of `--intervals`.
    def exclude_snp_input_ch = apply_vqsr_snp_filtered_ch.map { meta, tbi, vcf -> [ meta, vcf, tbi, file(params.magma_rrna_list) ] }
    GATK_SELECT_VARIANTS_EXCLUSION_SNP(exclude_snp_input_ch)
    def exclude_snp_vcftuple_ch = GATK_SELECT_VARIANTS_EXCLUSION_SNP.out.tbi.join(GATK_SELECT_VARIANTS_EXCLUSION_SNP.out.vcf)

    emit:
    snp_exc_vcf_ch = exclude_snp_vcftuple_ch    // rRNA-excluded SNP VCF — [meta, tbi, vcf]
    snp_inc_vcf_ch = apply_vqsr_snp_filtered_ch // rRNA-included SNP VCF — [meta, tbi, vcf]
}

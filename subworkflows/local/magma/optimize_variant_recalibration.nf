include { GATK_VARIANT_RECALIBRATOR as GATK_VARIANT_RECALIBRATOR_ANN7 } from '../../../modules/local/magma/gatk/variant_recalibrator'
include { GATK_VARIANT_RECALIBRATOR as GATK_VARIANT_RECALIBRATOR_ANN6 } from '../../../modules/local/magma/gatk/variant_recalibrator'
include { GATK_VARIANT_RECALIBRATOR as GATK_VARIANT_RECALIBRATOR_ANN5 } from '../../../modules/local/magma/gatk/variant_recalibrator'
include { GATK_VARIANT_RECALIBRATOR as GATK_VARIANT_RECALIBRATOR_ANN4 } from '../../../modules/local/magma/gatk/variant_recalibrator'
include { GATK_VARIANT_RECALIBRATOR as GATK_VARIANT_RECALIBRATOR_ANN3 } from '../../../modules/local/magma/gatk/variant_recalibrator'
include { GATK_VARIANT_RECALIBRATOR as GATK_VARIANT_RECALIBRATOR_ANN2 } from '../../../modules/local/magma/gatk/variant_recalibrator'
include { UTILS_ELIMINATE_ANNOTATION as UTILS_ELIMINATE_ANNOTATION_ANN7 } from '../../../modules/local/magma/utils/eliminate_annotation'
include { UTILS_ELIMINATE_ANNOTATION as UTILS_ELIMINATE_ANNOTATION_ANN6 } from '../../../modules/local/magma/utils/eliminate_annotation'
include { UTILS_ELIMINATE_ANNOTATION as UTILS_ELIMINATE_ANNOTATION_ANN5 } from '../../../modules/local/magma/utils/eliminate_annotation'
include { UTILS_ELIMINATE_ANNOTATION as UTILS_ELIMINATE_ANNOTATION_ANN4 } from '../../../modules/local/magma/utils/eliminate_annotation'
include { UTILS_ELIMINATE_ANNOTATION as UTILS_ELIMINATE_ANNOTATION_ANN3 } from '../../../modules/local/magma/utils/eliminate_annotation'
include { UTILS_ELIMINATE_ANNOTATION as UTILS_ELIMINATE_ANNOTATION_ANN2 } from '../../../modules/local/magma/utils/eliminate_annotation'
include { UTILS_SELECT_BEST_ANNOTATIONS } from '../../../modules/local/magma/utils/select_best_annotations'


workflow OPTIMIZE_VARIANT_RECALIBRATION {

    take:
    analysisType                  // val: "SNP" or "INDEL"
    select_variants_vcftuple_ch   // channel: [ meta, tbi, vcf ]
    args_ch                       // channel: val(resourceFilesArg string)
    resources_files_ch            // channel: path(vcf files)
    resources_file_indexes_ch     // channel: path(tbi files)

    main:

    // ANN7 — all 7 annotations
    GATK_VARIANT_RECALIBRATOR_ANN7(
        analysisType,
        '-an DP -an AS_QD -an AS_MQ -an AS_FS -an AS_SOR -an AS_MQRankSum -an AS_ReadPosRankSum',
        select_variants_vcftuple_ch,
        args_ch,
        resources_files_ch,
        resources_file_indexes_ch,
        params.magma_ref_fasta,
        [params.magma_ref_fasta_fai, params.magma_ref_fasta_dict]
    )

    UTILS_ELIMINATE_ANNOTATION_ANN7(
        analysisType,
        GATK_VARIANT_RECALIBRATOR_ANN7.out.annotationsLog
            .join(GATK_VARIANT_RECALIBRATOR_ANN7.out.tranchesFile)
    )

    // ANN6 — remove lowest-scoring annotation iteratively
    ann6_ch = UTILS_ELIMINATE_ANNOTATION_ANN7.out.reducedAnnotationsFile.map { it.text }

    GATK_VARIANT_RECALIBRATOR_ANN6(
        analysisType, ann6_ch, select_variants_vcftuple_ch,
        args_ch, resources_files_ch, resources_file_indexes_ch,
        params.magma_ref_fasta, [params.magma_ref_fasta_fai, params.magma_ref_fasta_dict]
    )

    UTILS_ELIMINATE_ANNOTATION_ANN6(
        analysisType,
        GATK_VARIANT_RECALIBRATOR_ANN6.out.annotationsLog
            .join(GATK_VARIANT_RECALIBRATOR_ANN6.out.tranchesFile)
    )

    // ANN5
    ann5_ch = UTILS_ELIMINATE_ANNOTATION_ANN6.out.reducedAnnotationsFile.map { it.text }

    GATK_VARIANT_RECALIBRATOR_ANN5(
        analysisType, ann5_ch, select_variants_vcftuple_ch,
        args_ch, resources_files_ch, resources_file_indexes_ch,
        params.magma_ref_fasta, [params.magma_ref_fasta_fai, params.magma_ref_fasta_dict]
    )

    UTILS_ELIMINATE_ANNOTATION_ANN5(
        analysisType,
        GATK_VARIANT_RECALIBRATOR_ANN5.out.annotationsLog
            .join(GATK_VARIANT_RECALIBRATOR_ANN5.out.tranchesFile)
    )

    // ANN4
    ann4_ch = UTILS_ELIMINATE_ANNOTATION_ANN5.out.reducedAnnotationsFile.map { it.text }

    GATK_VARIANT_RECALIBRATOR_ANN4(
        analysisType, ann4_ch, select_variants_vcftuple_ch,
        args_ch, resources_files_ch, resources_file_indexes_ch,
        params.magma_ref_fasta, [params.magma_ref_fasta_fai, params.magma_ref_fasta_dict]
    )

    UTILS_ELIMINATE_ANNOTATION_ANN4(
        analysisType,
        GATK_VARIANT_RECALIBRATOR_ANN4.out.annotationsLog
            .join(GATK_VARIANT_RECALIBRATOR_ANN4.out.tranchesFile)
    )

    // ANN3
    ann3_ch = UTILS_ELIMINATE_ANNOTATION_ANN4.out.reducedAnnotationsFile.map { it.text }

    GATK_VARIANT_RECALIBRATOR_ANN3(
        analysisType, ann3_ch, select_variants_vcftuple_ch,
        args_ch, resources_files_ch, resources_file_indexes_ch,
        params.magma_ref_fasta, [params.magma_ref_fasta_fai, params.magma_ref_fasta_dict]
    )

    UTILS_ELIMINATE_ANNOTATION_ANN3(
        analysisType,
        GATK_VARIANT_RECALIBRATOR_ANN3.out.annotationsLog
            .join(GATK_VARIANT_RECALIBRATOR_ANN3.out.tranchesFile)
    )

    // ANN2
    ann2_ch = UTILS_ELIMINATE_ANNOTATION_ANN3.out.reducedAnnotationsFile.map { it.text }

    GATK_VARIANT_RECALIBRATOR_ANN2(
        analysisType, ann2_ch, select_variants_vcftuple_ch,
        args_ch, resources_files_ch, resources_file_indexes_ch,
        params.magma_ref_fasta, [params.magma_ref_fasta_fai, params.magma_ref_fasta_dict]
    )

    UTILS_ELIMINATE_ANNOTATION_ANN2(
        analysisType,
        GATK_VARIANT_RECALIBRATOR_ANN2.out.annotationsLog
            .join(GATK_VARIANT_RECALIBRATOR_ANN2.out.tranchesFile)
    )

    // Collect all recal VCFs, tranches and annotation JSON files
    recal_vcf_files_ch = GATK_VARIANT_RECALIBRATOR_ANN7.out.recalVcfTuple
        .join(GATK_VARIANT_RECALIBRATOR_ANN6.out.recalVcfTuple)
        .join(GATK_VARIANT_RECALIBRATOR_ANN5.out.recalVcfTuple)
        .join(GATK_VARIANT_RECALIBRATOR_ANN4.out.recalVcfTuple)
        .join(GATK_VARIANT_RECALIBRATOR_ANN3.out.recalVcfTuple)
        .join(GATK_VARIANT_RECALIBRATOR_ANN2.out.recalVcfTuple)
        .flatten()
        .filter { it instanceof java.nio.file.Path }
        .collect()

    tranches_files_ch = GATK_VARIANT_RECALIBRATOR_ANN7.out.tranchesFile
        .join(GATK_VARIANT_RECALIBRATOR_ANN6.out.tranchesFile)
        .join(GATK_VARIANT_RECALIBRATOR_ANN5.out.tranchesFile)
        .join(GATK_VARIANT_RECALIBRATOR_ANN4.out.tranchesFile)
        .join(GATK_VARIANT_RECALIBRATOR_ANN3.out.tranchesFile)
        .join(GATK_VARIANT_RECALIBRATOR_ANN2.out.tranchesFile)
        .flatten()
        .filter { it instanceof java.nio.file.Path }
        .collect()

    annotations_and_tranches_json_files_ch = UTILS_ELIMINATE_ANNOTATION_ANN7.out.annotationsTranchesFile
        .join(UTILS_ELIMINATE_ANNOTATION_ANN6.out.annotationsTranchesFile)
        .join(UTILS_ELIMINATE_ANNOTATION_ANN5.out.annotationsTranchesFile)
        .join(UTILS_ELIMINATE_ANNOTATION_ANN4.out.annotationsTranchesFile)
        .join(UTILS_ELIMINATE_ANNOTATION_ANN3.out.annotationsTranchesFile)
        .join(UTILS_ELIMINATE_ANNOTATION_ANN2.out.annotationsTranchesFile)
        .flatten()
        .filter { it instanceof java.nio.file.Path }
        .collect()

    UTILS_SELECT_BEST_ANNOTATIONS(
        params.magma_vcf_name,
        annotations_and_tranches_json_files_ch,
        recal_vcf_files_ch,
        tranches_files_ch
    )

    emit:
    // optimized_vqsr_ch is the tuple needed by GATK_APPLY_VQSR: [ meta, variants_tbi, variants_vcf, recal_tbi, recal_vcf, tranches ]
    //
    // Port note: select_variants_vcftuple_ch is keyed on a meta MAP (its source,
    // GATK_SELECT_VARIANTS_SNP, emits tuple val(meta), ...). The best-annotation
    // outputs from UTILS_SELECT_BEST_ANNOTATIONS are keyed on joint_name (a
    // STRING — same module's `val(joint_name)` input). A plain .join on those
    // two collapses to an empty channel because meta_map ≠ string. That silent
    // empty channel meant GATK_APPLY_VQSR_SNP never fired in n11 — and the
    // entire downstream chain (MERGE_VCFS_INC → MAJOR_VARIANT → PHYLOGENY →
    // SNPDISTS / IQTREE / CLUSTER) never ran, which in turn caused MULTIQC to
    // fail with the snp_dists.tsv missing.
    //
    // Fix: project meta to meta.id for the join, then re-assemble the 6-tuple
    // with the meta map restored as the first element.
    optimized_vqsr_ch = select_variants_vcftuple_ch
        .map { meta, tbi, vcf -> [ meta.id, meta, tbi, vcf ] }
        .join(UTILS_SELECT_BEST_ANNOTATIONS.out.bestRecalVcfTuple)
        .join(UTILS_SELECT_BEST_ANNOTATIONS.out.bestTranchesFile)
        .map { _id, meta, tbi, vcf, recalTbi, recalVcf, tranches ->
            [ meta, tbi, vcf, recalTbi, recalVcf, tranches ]
        }
}

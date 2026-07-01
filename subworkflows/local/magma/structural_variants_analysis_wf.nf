/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    STRUCTURAL_VARIANTS_ANALYSIS_WF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    DELLY-based structural variant discovery + TBprofiler resistance profile.
    Mirrors torch-magma's workflows/structural_variants_analysis_wf.nf.

    DELLY-specific BWA mapping (no -k 100 tweak), merge, dedup, optional BQSR,
    DELLY call, filter, cohort merge, TBprofiler.
*/

include { BWA_MEM        as BWA_MEM_DELLY               } from '../../../modules/local/magma/bwa/mem'
include { SAMTOOLS_MERGE as SAMTOOLS_MERGE_DELLY        } from '../../../modules/local/magma/nf-core/samtools/merge/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_DELLY        } from '../../../modules/local/magma/nf-core/samtools/index/main'
include { GATK4_MARKDUPLICATES   as GATK_MARK_DUPLICATES_DELLY   } from '../../../modules/local/magma/nf-core/gatk4/markduplicates/main'
include { GATK4_BASERECALIBRATOR as GATK_BASE_RECALIBRATOR_DELLY } from '../../../modules/local/magma/nf-core/gatk4/baserecalibrator/main'
include { GATK4_APPLYBQSR        as GATK_APPLY_BQSR_DELLY        } from '../../../modules/local/magma/nf-core/gatk4/applybqsr/main'
include { DELLY_CALL                                   } from '../../../modules/local/magma/nf-core/delly/call/main'
include { BCFTOOLS_VIEW  as BCFTOOLS_VIEW_DELLY          } from '../../../modules/local/magma/nf-core/bcftools/view/main'
include { BCFTOOLS_MERGE as BCFTOOLS_MERGE_DELLY         } from '../../../modules/local/magma/bcftools/merge'
include { TBPROFILER_VCF_PROFILE as TBPROFILER_VCF_PROFILE_DELLY } from '../../../modules/local/magma/tbprofiler/vcf_profile'
include { TBPROFILER_COLLATE     as TBPROFILER_COLLATE_DELLY     } from '../../../modules/local/magma/tbprofiler/collate'


workflow STRUCTURAL_VARIANTS_ANALYSIS_WF {

    take:
    validated_reads_ch   // channel: [meta, [fastqs]]  (approved fastqs)
    samples_ch           // channel: [sample_name]      (all samples that passed QC)
    outdir               // val: output dir (for the vcf-list file)

    main:

    BWA_MEM_DELLY(
        validated_reads_ch,
        params.magma_ref_fasta,
        [params.magma_ref_fasta_dict, params.magma_ref_fasta_amb, params.magma_ref_fasta_ann,
         params.magma_ref_fasta_bwt, params.magma_ref_fasta_fai, params.magma_ref_fasta_pac,
         params.magma_ref_fasta_sa]
    )

    def delly_normalize_ch = BWA_MEM_DELLY.out
        .map { meta, bam ->
            def splitted = meta.id.split("\\.")
            def sampleId = splitted[0] + '.' + splitted[1]
            [ meta + [id: sampleId], bam ]
        }
        .groupTuple()

    // Filter to samples that passed cohort QC
    def delly_filtered_ch = samples_ch
        .map { [ it[0], it[0] ] }
        .join(delly_normalize_ch.map { meta, bam -> [ meta.id, meta, bam ] })
        .map { _id, _id2, meta, bam -> [ meta, bam ] }

    def samtools_merge_delly_input_ch = delly_filtered_ch.map { meta, bams -> [meta, bams, []] }
    SAMTOOLS_MERGE_DELLY(samtools_merge_delly_input_ch, Channel.value([ [id: 'none'], [], [], [] ]))
    GATK_MARK_DUPLICATES_DELLY(SAMTOOLS_MERGE_DELLY.out.bam, [], [])

    def recal_delly_ch
    if (!params.magma_skip_base_recalibration) {
        def base_recal_delly_input_ch = GATK_MARK_DUPLICATES_DELLY.out.bam.map { meta, bam -> [ meta, bam, [], [] ] }
        GATK_BASE_RECALIBRATOR_DELLY(
            base_recal_delly_input_ch,
            Channel.value([ [id:'ref'],   file(params.magma_ref_fasta)      ]),
            Channel.value([ [id:'ref'],   file(params.magma_ref_fasta_fai)  ]),
            Channel.value([ [id:'ref'],   file(params.magma_ref_fasta_dict) ]),
            Channel.value([ [id:'dbsnp'], file(params.magma_dbsnp_vcf)      ]),
            Channel.value([ [id:'dbsnp'], file(params.magma_dbsnp_vcf_tbi)  ])
        )
        def apply_bqsr_delly_input_ch = GATK_BASE_RECALIBRATOR_DELLY.out.table
            .join(GATK_MARK_DUPLICATES_DELLY.out.bam)
            .map { meta, table, bam -> [ meta, bam, [], table, [] ] }
        GATK_APPLY_BQSR_DELLY(
            apply_bqsr_delly_input_ch,
            file(params.magma_ref_fasta),
            file(params.magma_ref_fasta_fai),
            file(params.magma_ref_fasta_dict)
        )
        recal_delly_ch = GATK_APPLY_BQSR_DELLY.out.bam
    } else {
        recal_delly_ch = GATK_MARK_DUPLICATES_DELLY.out.bam
    }

    SAMTOOLS_INDEX_DELLY(recal_delly_ch)

    def delly_call_input_ch = SAMTOOLS_INDEX_DELLY.out.index
        .join(recal_delly_ch)
        .map { meta, bai, bam -> [ meta, bam, bai, [], [], [] ] }
    def delly_call_fasta_ch = Channel.value([ [id: 'ref'], file(params.magma_ref_fasta)     ])
    def delly_call_fai_ch   = Channel.value([ [id: 'ref'], file(params.magma_ref_fasta_fai) ])
    DELLY_CALL(delly_call_input_ch, delly_call_fasta_ch, delly_call_fai_ch, 'bcf')

    def bcftools_view_delly_input_ch = DELLY_CALL.out.bcf.join(DELLY_CALL.out.csi)
    BCFTOOLS_VIEW_DELLY(bcftools_view_delly_input_ch, [], [], [])

    def bcftools_view_delly_out_ch = BCFTOOLS_VIEW_DELLY.out.vcf.join(BCFTOOLS_VIEW_DELLY.out.index)

    def delly_vcfs_ch = bcftools_view_delly_out_ch
        .collect()
        .flatten()
        .filter { it instanceof java.nio.file.Path }
        .unique()
        .collect(sort: true)

    def delly_vcfs_file = bcftools_view_delly_out_ch
        .collect()
        .flatten()
        .filter { it instanceof java.nio.file.Path && it.getExtension() == "gz" }
        .map { it.name }
        .collectFile(name: "${outdir}/structural_variant_vcfs.txt", newLine: true)

    BCFTOOLS_MERGE_DELLY(
        params.magma_vcf_name,
        'delly',
        delly_vcfs_file,
        delly_vcfs_ch
    )

    def resistanceDb = []
    TBPROFILER_VCF_PROFILE_DELLY(BCFTOOLS_MERGE_DELLY.out, resistanceDb)
    TBPROFILER_COLLATE_DELLY(
        params.magma_vcf_name,
        TBPROFILER_VCF_PROFILE_DELLY.out.collect(),
        resistanceDb
    )

    emit:
    structural_variants_results_ch = TBPROFILER_COLLATE_DELLY.out.per_sample_results
}

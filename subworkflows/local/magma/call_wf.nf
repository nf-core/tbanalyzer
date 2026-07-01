/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CALL_WF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Per-sample variant calling (major + minor) and per-sample QC stats.
    Mirrors torch-magma's workflows/call_wf.nf.

    Stages:
      - merge per-library BAMs (SAMTOOLS_MERGE)
      - mark duplicates (GATK_MARK_DUPLICATES)
      - optional BQSR (GATK_BASE_RECALIBRATOR + GATK_APPLY_BQSR)
      - index (SAMTOOLS_INDEX)
      - major-variant GVCF (GATK_HAPLOTYPE_CALLER)
      - NTM-fraction estimate (LOFREQ_CALL_NTM)
      - minor variants (LOFREQ_INDELQUAL → LOFREQ_CALL → LOFREQ_FILTER →
          UTILS_REFORMAT_LOFREQ → BGZIP_LOFREQ → GATK_INDEX_FEATURE_FILE_LOFREQ)
      - per-sample QC (SAMTOOLS_STATS, GATK_COLLECT_WGS_METRICS, GATK_FLAG_STAT)
      - cohort-stats roll-up (UTILS_SAMPLE_STATS, UTILS_COHORT_STATS)
*/

include { SAMTOOLS_MERGE                           } from '../../../modules/local/magma/nf-core/samtools/merge/main'
include { SAMTOOLS_INDEX                           } from '../../../modules/local/magma/nf-core/samtools/index/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_LOFREQ  } from '../../../modules/local/magma/nf-core/samtools/index/main'
include { SAMTOOLS_STATS                           } from '../../../modules/local/magma/nf-core/samtools/stats/main'
include { GATK4_MARKDUPLICATES as GATK_MARK_DUPLICATES     } from '../../../modules/local/magma/nf-core/gatk4/markduplicates/main'
include { GATK4_BASERECALIBRATOR as GATK_BASE_RECALIBRATOR } from '../../../modules/local/magma/nf-core/gatk4/baserecalibrator/main'
include { GATK4_APPLYBQSR        as GATK_APPLY_BQSR        } from '../../../modules/local/magma/nf-core/gatk4/applybqsr/main'
include { GATK4_HAPLOTYPECALLER  as GATK_HAPLOTYPE_CALLER  } from '../../../modules/local/magma/nf-core/gatk4/haplotypecaller/main'
include { GATK_COLLECT_WGS_METRICS                 } from '../../../modules/local/magma/gatk/collect_wgs_metrics'
include { GATK_FLAG_STAT                           } from '../../../modules/local/magma/gatk/flag_stat'
include { LOFREQ_INDELQUAL                         } from '../../../modules/local/magma/nf-core/lofreq/indelqual/main'
include { LOFREQ_CALL                              } from '../../../modules/local/magma/lofreq/call'
include { LOFREQ_CALL_NTM                          } from '../../../modules/local/magma/lofreq/call_ntm'
include { LOFREQ_FILTER                            } from '../../../modules/local/magma/nf-core/lofreq/filter/main'
include { UTILS_SAMPLE_STATS                       } from '../../../modules/local/magma/utils/sample_stats'
include { UTILS_COHORT_STATS                       } from '../../../modules/local/magma/utils/cohort_stats'
include { UTILS_REFORMAT_LOFREQ                    } from '../../../modules/local/magma/utils/reformat_lofreq'
include { GATK4_INDEXFEATUREFILE as GATK_INDEX_FEATURE_FILE_LOFREQ } from '../../../modules/local/magma/nf-core/gatk4/indexfeaturefile/main'
include { BGZIP as BGZIP_LOFREQ                    } from '../../../modules/local/magma/bgzip/bgzip'


workflow CALL_WF {

    take:
    sorted_reads_ch   // channel: [ meta, sorted_reads.bam ] (per library, from MAP_WF)

    main:

    // Collapse per-library BAMs into one tuple per sample
    def normalize_libraries_ch = sorted_reads_ch
        .map { meta, bam ->
            def splitted = meta.id.split("\\.")
            def sampleId = splitted[0] + '.' + splitted[1]
            [ meta + [id: sampleId], bam ]
        }
        .groupTuple()

    // nf-core SAMTOOLS_MERGE adds index_files + fasta value tuple inputs;
    // for BAM-only merging both are empty. Pad and pass an empty fasta tuple.
    def samtools_merge_input_ch = normalize_libraries_ch.map { meta, bams -> [meta, bams, []] }
    def samtools_merge_ref_ch   = Channel.value([ [id: 'none'], [], [], [] ])
    SAMTOOLS_MERGE(samtools_merge_input_ch, samtools_merge_ref_ch)

    // nf-core gatk4/markduplicates also takes (optional) fasta/fai for CRAM
    // conversion; we run in BAM mode so pass [] for both.
    GATK_MARK_DUPLICATES(SAMTOOLS_MERGE.out.bam, [], [])

    // BQSR (disabled by default for Mtb) — uses standard nf-core modules.
    def recalibrated_bam_ch
    if (!params.magma_skip_base_recalibration) {
        def base_recal_input_ch = GATK_MARK_DUPLICATES.out.bam.map { meta, bam -> [ meta, bam, [], [] ] }
        GATK_BASE_RECALIBRATOR(
            base_recal_input_ch,
            Channel.value([ [id:'ref'],   file(params.magma_ref_fasta)      ]),
            Channel.value([ [id:'ref'],   file(params.magma_ref_fasta_fai)  ]),
            Channel.value([ [id:'ref'],   file(params.magma_ref_fasta_dict) ]),
            Channel.value([ [id:'dbsnp'], file(params.magma_dbsnp_vcf)      ]),
            Channel.value([ [id:'dbsnp'], file(params.magma_dbsnp_vcf_tbi)  ])
        )
        def apply_bqsr_input_ch = GATK_BASE_RECALIBRATOR.out.table
            .join(GATK_MARK_DUPLICATES.out.bam)
            .map { meta, table, bam -> [ meta, bam, [], table, [] ] }
        GATK_APPLY_BQSR(
            apply_bqsr_input_ch,
            file(params.magma_ref_fasta),
            file(params.magma_ref_fasta_fai),
            file(params.magma_ref_fasta_dict)
        )
        recalibrated_bam_ch = GATK_APPLY_BQSR.out.bam
    } else {
        recalibrated_bam_ch = GATK_MARK_DUPLICATES.out.bam
    }

    SAMTOOLS_INDEX(recalibrated_bam_ch)

    // Rebuild the [meta, bai, bam] tuple downstream local modules expect.
    def recalibrated_indexed_bam_ch = SAMTOOLS_INDEX.out.index.join(recalibrated_bam_ch)

    // HaplotypeCaller (major variants / GVCF).
    def haplotype_caller_input_ch = recalibrated_indexed_bam_ch.map { meta, bai, bam -> [ meta, bam, bai, [], [] ] }
    GATK_HAPLOTYPE_CALLER(
        haplotype_caller_input_ch,
        Channel.value([ [id: 'ref'],  file(params.magma_ref_fasta)      ]),
        Channel.value([ [id: 'ref'],  file(params.magma_ref_fasta_fai)  ]),
        Channel.value([ [id: 'ref'],  file(params.magma_ref_fasta_dict) ]),
        Channel.value([ [id: 'none'], [] ]),
        Channel.value([ [id: 'none'], [] ])
    )

    // NTM contamination estimate via LoFreq call at 16S locus
    LOFREQ_CALL_NTM(
        recalibrated_indexed_bam_ch,
        params.magma_ref_fasta,
        [params.magma_ref_fasta_fai]
    )

    // LoFreq minor-variant calling
    def lofreq_indelqual_ref_ch = Channel.value([ [id: 'ref'], file(params.magma_ref_fasta) ])
    LOFREQ_INDELQUAL(recalibrated_bam_ch, lofreq_indelqual_ref_ch)
    SAMTOOLS_INDEX_LOFREQ(LOFREQ_INDELQUAL.out.bam)
    def lofreq_indexed_bam_ch = SAMTOOLS_INDEX_LOFREQ.out.index.join(LOFREQ_INDELQUAL.out.bam)
    LOFREQ_CALL(lofreq_indexed_bam_ch, params.magma_ref_fasta, [params.magma_ref_fasta_fai])
    LOFREQ_FILTER(LOFREQ_CALL.out)

    // Reformat LoFreq VCFs for downstream merging
    UTILS_REFORMAT_LOFREQ(LOFREQ_CALL.out)
    BGZIP_LOFREQ(UTILS_REFORMAT_LOFREQ.out)
    GATK_INDEX_FEATURE_FILE_LOFREQ(BGZIP_LOFREQ.out)
    def lofreq_vcf_tuple_pairs_ch = GATK_INDEX_FEATURE_FILE_LOFREQ.out.index
        .join(BGZIP_LOFREQ.out)
        .map { _meta, tbi, vcf -> [ tbi, vcf ] }

    // Per-sample QC stats
    def samtools_stats_input_ch = recalibrated_bam_ch.map { meta, bam -> [meta, bam, []] }
    def samtools_stats_ref_ch   = Channel.value([ [id: 'ref'], file(params.magma_ref_fasta), file(params.magma_ref_fasta_fai) ])
    SAMTOOLS_STATS(samtools_stats_input_ch, samtools_stats_ref_ch)
    GATK_COLLECT_WGS_METRICS(recalibrated_bam_ch, params.magma_ref_fasta)
    GATK_FLAG_STAT(recalibrated_bam_ch, params.magma_ref_fasta, [params.magma_ref_fasta_fai, params.magma_ref_fasta_dict])

    sample_stats_ch = SAMTOOLS_STATS.out.stats
        .join(GATK_COLLECT_WGS_METRICS.out)
        .join(GATK_FLAG_STAT.out)
        .join(LOFREQ_CALL_NTM.out)

    UTILS_SAMPLE_STATS(sample_stats_ch)
    UTILS_COHORT_STATS(UTILS_SAMPLE_STATS.out.collect())

    emit:
    cohort_stats_tsv                 = UTILS_COHORT_STATS.out
    gvcf_tbi_ch                      = GATK_HAPLOTYPE_CALLER.out.tbi
    gvcf_vcf_ch                      = GATK_HAPLOTYPE_CALLER.out.vcf
    reformatted_lofreq_vcfs_tuple_ch = lofreq_vcf_tuple_pairs_ch.collect(sort: true)
}

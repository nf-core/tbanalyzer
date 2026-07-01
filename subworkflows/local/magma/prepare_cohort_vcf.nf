include { GATK4_COMBINEGVCFS as GATK_COMBINE_GVCFS } from '../../../modules/local/magma/nf-core/gatk4/combinegvcfs/main'
include { GATK4_GENOTYPEGVCFS as GATK_GENOTYPE_GVCFS } from '../../../modules/local/magma/nf-core/gatk4/genotypegvcfs/main'
include { SNPEFF                          } from '../../../modules/local/magma/snpeff/snpeff'
include { BGZIP                           } from '../../../modules/local/magma/bgzip/bgzip'
include { GATK4_INDEXFEATUREFILE as GATK_INDEX_FEATURE_FILE_COHORT } from '../../../modules/local/magma/nf-core/gatk4/indexfeaturefile/main'


workflow PREPARE_COHORT_VCF {

    take:
    cohort_gvcfs_ch   // channel: [ [meta], path(gvcf), path(tbi) ]

    main:

    // Build the [meta, [gvcfs], [tbis]] input shape nf-core gatk4/combinegvcfs
    // expects. Collect every path in one go (avoids .merge() losing the list
    // structure), then partition by suffix inside the map closure.
    def combine_input_ch = cohort_gvcfs_ch
        .flatten()
        .filter { it instanceof java.nio.file.Path }
        .collect()
        .map { paths ->
            def gvcfs = paths.findAll { it.name.endsWith('.gz') }
            def tbis  = paths.findAll { it.name.endsWith('.tbi') }
            if (params.magma_use_ref_gvcf) {
                gvcfs = gvcfs + [ file(params.magma_ref_gvcf,     checkIfExists: true) ]
                tbis  = tbis  + [ file(params.magma_ref_gvcf_tbi, checkIfExists: true) ]
            }
            [ [id: params.magma_vcf_name], gvcfs, tbis ]
        }

    GATK_COMBINE_GVCFS(
        combine_input_ch,
        file(params.magma_ref_fasta),
        file(params.magma_ref_fasta_fai),
        file(params.magma_ref_fasta_dict)
    )

    // Downstream wants [meta, tbi, vcf]. nf-core emits combined_gvcf (vcf) and tbi separately
    // (tbi emit added via patch — gatk auto-creates .tbi for any .vcf.gz output but the
    // stock nf-core module doesn't expose it).
    def combined_ch = GATK_COMBINE_GVCFS.out.combined_gvcf
        .join(GATK_COMBINE_GVCFS.out.tbi)
        .map { meta, vcf, tbi -> [ meta, tbi, vcf ] }

    // nf-core GenotypeGVCFs input: [meta, vcf, gvcf_index, intervals, intervals_index]
    // Reorder combined_ch [meta, tbi, vcf] → [meta, vcf, tbi, [], []] and supply
    // empty value tuples for the unused dbsnp / dbsnp_tbi inputs.
    def genotype_input_ch = combined_ch.map { meta, tbi, vcf -> [ meta, vcf, tbi, [], [] ] }
    GATK_GENOTYPE_GVCFS(
        genotype_input_ch,
        Channel.value([ [id: 'ref'],  file(params.magma_ref_fasta)      ]),
        Channel.value([ [id: 'ref'],  file(params.magma_ref_fasta_fai)  ]),
        Channel.value([ [id: 'ref'],  file(params.magma_ref_fasta_dict) ]),
        Channel.value([ [id: 'none'], [] ]),
        Channel.value([ [id: 'none'], [] ])
    )

    SNPEFF(GATK_GENOTYPE_GVCFS.out.vcf, params.magma_ref_fasta)

    BGZIP(SNPEFF.out)

    GATK_INDEX_FEATURE_FILE_COHORT(BGZIP.out)

    emit:
    // nf-core gatk4/indexfeaturefile emits only [meta, tbi] (emit: index).
    // The downstream PREPARE_COHORT_VCF emit shape — [meta, tbi, vcf] —
    // is rebuilt by joining the index output with BGZIP.out on meta.
    cohort_vcf_and_index_ch = GATK_INDEX_FEATURE_FILE_COHORT.out.index.join(BGZIP.out)
}

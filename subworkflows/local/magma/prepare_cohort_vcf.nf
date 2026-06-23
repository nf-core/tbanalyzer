include { GATK_COMBINE_GVCFS              } from '../../../modules/local/magma/gatk/combine_gvcfs'
include { GATK4_GENOTYPEGVCFS as GATK_GENOTYPE_GVCFS } from '../../../modules/local/magma/nf-core/gatk4/genotypegvcfs/main'
include { SNPEFF                          } from '../../../modules/local/magma/snpeff/snpeff'
include { BGZIP                           } from '../../../modules/local/magma/bgzip/bgzip'
include { GATK4_INDEXFEATUREFILE as GATK_INDEX_FEATURE_FILE_COHORT } from '../../../modules/local/magma/nf-core/gatk4/indexfeaturefile/main'


workflow PREPARE_COHORT_VCF {

    take:
    cohort_gvcfs_ch   // channel: [ [meta], path(gvcf), path(tbi) ]

    main:

    // Build the --variant string by collecting all .gz filenames
    gvcfs_string_ch = cohort_gvcfs_ch
        .flatten()
        .filter { it instanceof java.nio.file.Path && it.getExtension() == "gz" }
        .map { it -> file(it).name }
        .reduce { a, b -> "$a --variant $b" }

    // Collect all GVCFs (paths) for staging
    gvcfs_paths_ch = cohort_gvcfs_ch
        .flatten()
        .filter { it instanceof java.nio.file.Path }
        .collect()

    def refExitRifGvcf    = params.magma_use_ref_gvcf ? file(params.magma_ref_gvcf,     checkIfExists: true) : []
    def refExitRifGvcfTbi = params.magma_use_ref_gvcf ? file(params.magma_ref_gvcf_tbi, checkIfExists: true) : []

    GATK_COMBINE_GVCFS(
        params.magma_vcf_name,
        gvcfs_string_ch,
        gvcfs_paths_ch,
        params.magma_ref_fasta,
        refExitRifGvcf,
        refExitRifGvcfTbi,
        [params.magma_ref_fasta_fai, params.magma_ref_fasta_dict]
    )

    // Wrap the joint_name output in a meta map for downstream consistency
    combined_ch = GATK_COMBINE_GVCFS.out
        .map { joint_name, tbi, vcf -> [ [id: joint_name], tbi, vcf ] }

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

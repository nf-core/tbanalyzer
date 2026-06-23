include { GATK_SELECT_VARIANTS as GATK_SELECT_VARIANTS_PHYLOGENY } from '../../../modules/local/magma/gatk/select_variants'
include { GATK_VARIANTS_TO_TABLE                                  } from '../../../modules/local/magma/gatk/variants_to_table'
include { SNPSITES                                                } from '../../../modules/local/magma/snpsites/snpsites'
include { SNPDISTS                                                } from '../../../modules/local/magma/nf-core/snpdists/main'
include { IQTREE                                                  } from '../../../modules/local/magma/iqtree/iqtree'


workflow PHYLOGENY_ANALYSIS {

    take:
    prefix_ch      // val: prefix string used in output filenames (e.g. 'IncComplex')
    arg_files_ch   // channel: paths to exclusion intervals / resource files
    vcf_ch         // channel: [ meta, tbi, vcf ]

    main:

    // Build the -XL (exclude-intervals) argument string from interval/list files
    args_ch = arg_files_ch
        .filter { it instanceof java.nio.file.Path && (it.getExtension() == "gz" || it.getExtension() == "list") }
        .reduce('') { a, b -> "$a -XL ${b.getName()}" }

    resources_files_ch = arg_files_ch
        .filter { it instanceof java.nio.file.Path && (it.getExtension() == "gz" || it.getExtension() == "list") }
        .collect()
        .ifEmpty([])

    resources_file_indexes_ch = arg_files_ch
        .filter { it instanceof java.nio.file.Path && it.getExtension() == "tbi" }
        .collect()
        .ifEmpty([])

    GATK_SELECT_VARIANTS_PHYLOGENY(
        'SNP',
        prefix_ch,
        vcf_ch,
        args_ch,
        resources_files_ch,
        resources_file_indexes_ch,
        params.magma_ref_fasta,
        [params.magma_ref_fasta_fai, params.magma_ref_fasta_dict]
    )

    GATK_VARIANTS_TO_TABLE(prefix_ch, GATK_SELECT_VARIANTS_PHYLOGENY.out.variantsVcfTuple)

    SNPSITES(prefix_ch, GATK_VARIANTS_TO_TABLE.out)

    // SNPDISTS uses the standard nf-core module (single meta-channel input).
    // The phylogeny prefix that the other local modules in this subworkflow take
    // as a separate `val` channel is folded into meta as `phylo_prefix` so that
    // `conf/modules.config` can set ext.prefix = "${meta.id}.${meta.phylo_prefix}.snp_dists"
    // and reproduce torch-magma's filename joint.<prefix>.snp_dists.tsv exactly.
    snpdists_input_ch = prefix_ch
        .combine(SNPSITES.out)
        .map { phylo_prefix, meta, fasta -> [ meta + [phylo_prefix: phylo_prefix], fasta ] }

    SNPDISTS(snpdists_input_ch)

    IQTREE(prefix_ch, SNPSITES.out)

    emit:
    snpsites_tree_tuple = SNPSITES.out.join(IQTREE.out.tree_tuple) // [ meta, fasta, treefile ]
    // Match the prior emit shape (bare path channel) by dropping meta — the only
    // downstream consumer (magma.nf MULTIQC mix) doesn't need it.
    snp_dists_ch        = SNPDISTS.out.tsv.map { _meta, tsv -> tsv }
}

include { GATK_SELECT_VARIANTS as GATK_SELECT_VARIANTS_PHYLOGENY } from '../../../modules/local/magma/gatk/select_variants'
include { GATK4_VARIANTSTOTABLE as GATK_VARIANTS_TO_TABLE         } from '../../../modules/local/magma/nf-core/gatk4/variantstotable/main'
include { UTILS_VARIANT_TABLE_TO_FASTA                            } from '../../../modules/local/magma/utils/variant_table_to_fasta'
include { SNPSITES                                                } from '../../../modules/local/magma/snpsites/snpsites'
include { SNPDISTS                                                } from '../../../modules/local/magma/nf-core/snpdists/main'
include { IQTREE                                                  } from '../../../modules/local/magma/nf-core/iqtree/main'


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

    // nf-core gatk4/variantstotable input: [meta, vcf, tbi, args_file, include_intervals, exclude_intervals]
    // + 3 ref value tuples. Same prefix-into-meta adapter so ext.prefix can
    // recompute the joint.<prefix>.table filename.
    def vtot_input_ch = prefix_ch
        .combine(GATK_SELECT_VARIANTS_PHYLOGENY.out.variantsVcfTuple)
        .map { phylo_prefix, meta, tbi, vcf -> [ meta + [phylo_prefix: phylo_prefix], vcf, tbi, [], [], [] ] }
    GATK_VARIANTS_TO_TABLE(
        vtot_input_ch,
        Channel.value([ [id: 'ref'], file(params.magma_ref_fasta)      ]),
        Channel.value([ [id: 'ref'], file(params.magma_ref_fasta_fai)  ]),
        Channel.value([ [id: 'ref'], file(params.magma_ref_fasta_dict) ])
    )

    // The local module bundled `variant_table_to_fasta.py` after gatk's table.
    // Split out: now a dedicated UTILS_VARIANT_TABLE_TO_FASTA local module.
    UTILS_VARIANT_TABLE_TO_FASTA(GATK_VARIANTS_TO_TABLE.out.table)

    // SNPSITES expects (prefix_ch, [meta, fasta]). Strip phylo_prefix from
    // UTILS_VARIANT_TABLE_TO_FASTA.out.fasta meta so it joins compatibly.
    def vtt_fasta_clean_ch = UTILS_VARIANT_TABLE_TO_FASTA.out.fasta.map { meta, fasta ->
        [ meta.findAll { k, _v -> k != 'phylo_prefix' }, fasta ]
    }

    SNPSITES(prefix_ch, vtt_fasta_clean_ch)

    // SNPDISTS uses the standard nf-core module (single meta-channel input).
    // The phylogeny prefix that the other local modules in this subworkflow take
    // as a separate `val` channel is folded into meta as `phylo_prefix` so that
    // `conf/modules.config` can set ext.prefix = "${meta.id}.${meta.phylo_prefix}.snp_dists"
    // and reproduce torch-magma's filename joint.<prefix>.snp_dists.tsv exactly.
    snpdists_input_ch = prefix_ch
        .combine(SNPSITES.out)
        .map { phylo_prefix, meta, fasta -> [ meta + [phylo_prefix: phylo_prefix], fasta ] }

    SNPDISTS(snpdists_input_ch)

    // IQTREE: same prefix-into-meta adapter as SNPDISTS. nf-core IQTREE takes
    // tuple val(meta), path(alignment), path(tree) — 3-element with empty tree;
    // plus 13 optional path args for advanced features (all []).
    iqtree_input_ch = prefix_ch
        .combine(SNPSITES.out)
        .map { phylo_prefix, meta, fasta -> [ meta + [phylo_prefix: phylo_prefix], fasta, [] ] }
    IQTREE(iqtree_input_ch, [], [], [], [], [], [], [], [], [], [], [], [])

    // Strip phylo_prefix from IQTREE.out.phylogeny meta so it joins cleanly with
    // SNPSITES.out (which doesn't carry phylo_prefix).
    def iqtree_phylogeny_clean_ch = IQTREE.out.phylogeny.map { meta, treefile ->
        [ meta.findAll { k, _v -> k != 'phylo_prefix' }, treefile ]
    }

    emit:
    snpsites_tree_tuple = SNPSITES.out.join(iqtree_phylogeny_clean_ch) // [ meta, fasta, treefile ]
    // Match the prior emit shape (bare path channel) by dropping meta — the only
    // downstream consumer (magma.nf MULTIQC mix) doesn't need it.
    snp_dists_ch        = SNPDISTS.out.tsv.map { _meta, tsv -> tsv }
}

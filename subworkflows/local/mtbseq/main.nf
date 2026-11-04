/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { QUALITY_CHECK } from './quality_check'
include { PARALLEL_MODE } from './parallel_mode'

include { TBFULL   } from '../../../modules/local/mtbseq/tbfull/main'
include { TBJOIN   } from '../../../modules/local/mtbseq/tbjoin/main'
include { TBAMEND  } from '../../../modules/local/mtbseq/tbamend/main'
include { TBGROUPS } from '../../../modules/local/mtbseq/tbgroups/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MTBSEQ ANALYSIS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// Self-contained MTBseq analysis core: QC + (serial or parallel) MTBseq workflow.
// Emits MultiQC-ready files and software versions so that the calling pipeline
// (the nf-core/tbanalyzer meta-pipeline) owns the MultiQC / reporting steps.
//
workflow MTBSEQ {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    ch_reference_files = Channel.value([params.mtbseq_resilist,
                                        params.mtbseq_intregions,
                                        params.mtbseq_categories,
                                        params.mtbseq_basecalib])

    QUALITY_CHECK(ch_samplesheet)

    ch_multiqc_files = ch_multiqc_files.mix(QUALITY_CHECK.out.multiqc_files)

    if(!params.mtbseq_only_qc) {

        if( params.mtbseq_parallel ) {

                ch_reads =  QUALITY_CHECK.out.reads_and_meta_ch

                ch_reads.dump(tag: 'ch_reads')

                PARALLEL_MODE(ch_reads,
                              QUALITY_CHECK.out.derived_cohort_tsv,
                              ch_reference_files)

                ch_versions =  ch_versions.mix(PARALLEL_MODE.out.versions)
                ch_multiqc_files =  ch_multiqc_files.mix(PARALLEL_MODE.out.multiqc_files)

            } else {

                //NOTE: Defaults to the normal analysis as implemented in MTBseq

                ch_reads =  QUALITY_CHECK.out.reads_ch.collect()

                ch_reads.dump(tag: 'ch_reads')

                TBFULL( ch_reads,
                        params.mtbseq_user,
                        ch_reference_files )

                // COHORT STEPS

                TBJOIN( TBFULL.out.position_variants.collect(sort:true),
                        TBFULL.out.position_tables.collect(sort:true),
                        QUALITY_CHECK.out.derived_cohort_tsv,
                        params.mtbseq_user,
                        ch_reference_files)

                TBAMEND(TBJOIN.out.joint_samples,
                        QUALITY_CHECK.out.derived_cohort_tsv,
                        params.mtbseq_user,
                        ch_reference_files)

                TBGROUPS(TBAMEND.out.samples_amended,
                        QUALITY_CHECK.out.derived_cohort_tsv,
                        params.mtbseq_user,
                        ch_reference_files)

                ch_versions = ch_versions.mix(TBFULL.out.versions)
                ch_multiqc_files = ch_multiqc_files.mix(TBFULL.out.classification)
                                        .mix(TBFULL.out.statistics)
                                        .mix(TBGROUPS.out.distance_matrix.first())
                                        .mix(TBGROUPS.out.groups.first())

        }
    }

    emit:
    multiqc_files = ch_multiqc_files // channel: [ files for MultiQC ]
    versions      = ch_versions      // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

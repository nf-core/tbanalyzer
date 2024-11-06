include { TBBWA      } from '../../../modules/local/mtbseq/tbbwa/main'
include { TBREFINE   } from '../../../modules/local/mtbseq/tbrefine/main'
include { TBPILE     } from '../../../modules/local/mtbseq/tbpile/main'
include { TBLIST     } from '../../../modules/local/mtbseq/tblist/main'
include { TBVARIANTS } from '../../../modules/local/mtbseq/tbvariants/main'
include { TBSTATS    } from '../../../modules/local/mtbseq/tbstats/main'
include { TBSTRAINS  } from '../../../modules/local/mtbseq/tbstrains/main'
include { TBJOIN     } from '../../../modules/local/mtbseq/tbjoin/main'
include { TBAMEND    } from '../../../modules/local/mtbseq/tbamend/main'
include { TBGROUPS   } from '../../../modules/local/mtbseq/tbgroups/main'



workflow PARALLEL_MODE {
    take:
        reads_ch
        derived_cohort_tsv
        references_ch

    main:

        ch_versions = Channel.empty()
        ch_multiqc_files = Channel.empty()

        TBBWA(reads_ch, params.mtbseq_user, references_ch)
        TBREFINE(TBBWA.out.bam_tuple, params.mtbseq_user, references_ch)
        TBPILE(TBREFINE.out.gatk_bam, params.mtbseq_user, references_ch)
        TBLIST(TBPILE.out.mpileup, params.mtbseq_user, references_ch)
        TBVARIANTS(TBLIST.out.position_table_tuple, params.mtbseq_user, references_ch)

    // NOTE: These are part of per-sample-analysis but they need the output from
    // all other processes to compute the metrics for the cohort.
        TBSTATS(TBBWA.out.bam.collect(),
                TBLIST.out.position_table.collect(),
                params.mtbseq_user,
                references_ch)

        TBSTRAINS(TBLIST.out.position_table.collect(),
                  params.mtbseq_user,
                  references_ch)

    // COHORT STEPS


        TBJOIN(TBVARIANTS.out.tbjoin_input.collect(sort:true),
               TBLIST.out.position_table.collect(sort:true),
               derived_cohort_tsv,
               params.mtbseq_user,
               references_ch)

        TBAMEND(TBJOIN.out.joint_samples,
                derived_cohort_tsv,
                params.mtbseq_user,
                references_ch)

        TBGROUPS(TBAMEND.out.samples_amended,
                 derived_cohort_tsv,
                 params.mtbseq_user,
                 references_ch)

        ch_versions = ch_versions.mix(TBGROUPS.out.versions.first())
        ch_multiqc_files = ch_multiqc_files.mix(TBSTRAINS.out.classification)
                                .mix(TBSTATS.out.statistics)
                                .mix(TBGROUPS.out.distance_matrix.first())
                                .mix(TBGROUPS.out.groups.first())

    emit:
        versions       = ch_versions
        multiqc_files  = ch_multiqc_files.collect()
}

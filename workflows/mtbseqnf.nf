/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { QUALITY_CHECK      } from '../subworkflows/local/mtbseq/quality_check.nf'
include { PARALLEL_MODE      } from "../subworkflows/local/mtbseq/parallel_mode.nf"

include { TBFULL             } from '../modules/local/mtbseq/tbfull/main'
include { TBJOIN             } from '../modules/local/mtbseq/tbjoin/main'
include { TBAMEND            } from '../modules/local/mtbseq/tbamend/main'
include { TBGROUPS           } from '../modules/local/mtbseq/tbgroups/main'
include { MULTIQC            } from '../modules/nf-core/multiqc/main'


include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_tbanalyzer_pipeline'



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow MTBSEQ_NF {

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


    ch_versions = ch_versions.mix(QUALITY_CHECK.out.versions)
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

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MULTIQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )


    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

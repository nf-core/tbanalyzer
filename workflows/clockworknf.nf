/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CLOCKWORK_NF — tbanalyzer --mode clockwork
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Vendored, version-isolated port of clockwork's DB-free variant_call path
    (clockwork-nf). Every process pins ghcr.io/iqbal-lab-org/clockwork:v0.12.5 so
    tool versions match the baseline clockwork tool (parity contract).

      TRIM_READS -> MAP_READS -> { CALL_VARS_SAMTOOLS || CALL_VARS_CORTEX }
                 -> MINOS_ADJUDICATE -> minos/final.vcf
----------------------------------------------------------------------------------------
*/

include { TRIM_READS         } from '../modules/local/clockwork/trim_reads/main'
include { MAP_READS          } from '../modules/local/clockwork/map_reads/main'
include { CALL_VARS_SAMTOOLS } from '../modules/local/clockwork/call_vars_samtools/main'
include { CALL_VARS_CORTEX   } from '../modules/local/clockwork/call_vars_cortex/main'
include { MINOS_ADJUDICATE   } from '../modules/local/clockwork/minos_adjudicate/main'

workflow CLOCKWORK_NF {

    take:
    samplesheet     // channel: [ val(meta), [ fastq_1, fastq_2 ] ]  (from PIPELINE_INITIALISATION)

    main:
    ch_versions    = Channel.empty()
    multiqc_report = Channel.empty()   // clockwork mode produces VCFs, no MultiQC report

    ref_dir    = file(params.clockwork_ref_dir, checkIfExists: true)
    mem_height = params.clockwork_cortex_mem_height

    TRIM_READS(samplesheet)
    ch_versions = ch_versions.mix(TRIM_READS.out.versions)

    MAP_READS(TRIM_READS.out.trimmed, ref_dir)
    ch_versions = ch_versions.mix(MAP_READS.out.versions)

    CALL_VARS_SAMTOOLS(MAP_READS.out.bam, ref_dir)
    ch_versions = ch_versions.mix(CALL_VARS_SAMTOOLS.out.versions)

    CALL_VARS_CORTEX(MAP_READS.out.bam, ref_dir, mem_height)
    ch_versions = ch_versions.mix(CALL_VARS_CORTEX.out.versions)

    ch_minos_in = CALL_VARS_SAMTOOLS.out.calls.join(CALL_VARS_CORTEX.out.cortex_dir, by: 0)

    MINOS_ADJUDICATE(ch_minos_in, ref_dir)
    ch_versions = ch_versions.mix(MINOS_ADJUDICATE.out.versions)

    emit:
    vcf            = MINOS_ADJUDICATE.out.vcf   // channel: [ val(meta), path(final.vcf) ]
    multiqc_report = multiqc_report             // channel: (empty) — interface parity with other modes
    versions       = ch_versions
}

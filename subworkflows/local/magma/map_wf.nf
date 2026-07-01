/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MAP_WF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Per-sample mapping via BWA-MEM with the MAGMA tuning (-k 100 for Mtb
    contaminant-removal sensitivity).  Mirrors torch-magma's
    workflows/map_wf.nf.
*/

include { BWA_MEM } from '../../../modules/local/magma/bwa/mem'


workflow MAP_WF {

    take:
    approved_fastqs_ch   // channel: [ meta, [fastqs] ]

    main:

    BWA_MEM(
        approved_fastqs_ch,
        params.magma_ref_fasta,
        [params.magma_ref_fasta_dict, params.magma_ref_fasta_amb, params.magma_ref_fasta_ann,
         params.magma_ref_fasta_bwt, params.magma_ref_fasta_fai, params.magma_ref_fasta_pac,
         params.magma_ref_fasta_sa]
    )

    emit:
    sorted_reads_ch = BWA_MEM.out   // [ meta, sorted_reads.bam ] per library
}

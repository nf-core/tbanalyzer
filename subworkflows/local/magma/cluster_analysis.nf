include { CLUSTERPICKER as CLUSTERPICKER_5SNP  } from '../../../modules/local/magma/clusterpicker/clusterpicker'
include { CLUSTERPICKER as CLUSTERPICKER_12SNP } from '../../../modules/local/magma/clusterpicker/clusterpicker'


workflow CLUSTER_ANALYSIS {

    take:
    cluster_files_ch   // channel: [ meta, fasta, treefile ]
    prefix             // val: prefix string for output filenames

    main:

    CLUSTERPICKER_5SNP(cluster_files_ch,   5, prefix)
    CLUSTERPICKER_12SNP(cluster_files_ch, 12, prefix)

    emit:
    cluster_5snp_ch  = CLUSTERPICKER_5SNP.out
    cluster_12snp_ch = CLUSTERPICKER_12SNP.out
}

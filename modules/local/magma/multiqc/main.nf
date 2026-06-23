process MULTIQC {
    label 'process_single'

    input:
        path(multiqc_config)
        path("*")

    output:
        path("*multiqc_report.html"), emit: report
        path("multiqc_data")        , emit: data

    when:
    task.ext.when == null || task.ext.when

    // Faithful port of torch-magma modules/local/multiqc/multiqc.nf.
    // preprocess_multiqc_input.py builds the MAGMA custom MultiQC tables from the
    // merged cohort stats + the ExComplex SNP-distance matrix (both staged via the
    // collected `path("*")` input), then MultiQC renders them with the MAGMA
    // assets/multiqc_config.yml. Command kept byte-identical to the reference so
    // the emitted .command.sh matches standard MAGMA (NOT the nf-core MULTIQC
    // module, whose `multiqc --force --config ?/… .` form + missing preprocess
    // step diverge from — and fail against — the MAGMA multiqc_config.yml).
    script:
    def config = multiqc_config ? "--config ${multiqc_config}" : ''
    def arg_skip_merge_analysis = !params.magma_skip_merge_analysis ? '' : '--skip_merge_analysis'
    """
    preprocess_multiqc_input.py \\
        ${arg_skip_merge_analysis} \\
        --merged_cohort_stats joint.merged_cohort_stats.tsv \\
        --distance_matrix joint.ExDR.ExComplex.snp_dists.tsv

    multiqc ${config} .
    """

    stub:
    """
    mkdir multiqc_data
    touch multiqc_report.html
    """
}

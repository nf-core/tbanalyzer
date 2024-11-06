process TBVARIANTS {
    tag "${meta.id}"
    label 'process_single'

    conda "bioconda::mtbseq=1.1.0"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mtbseq:1.1.0--hdfd78af_0' :
        'biocontainers/mtbseq:1.1.0--hdfd78af_0' }"


    input:
        tuple val(meta), path("Position_Tables/*")
        env(USER)
        tuple path(ref_resistance_list), path(ref_interesting_regions), path(ref_gene_categories), path(ref_base_quality_recalibration)

    output:
        path("Called/${meta.id}_${meta.library}*gatk_position_{uncovered,variants}*.tab")
        path("Called/${meta.id}_${meta.library}*gatk_position_variants*.tab"), emit: tbjoin_input

    script:
        def args = task.ext.args ?: "--mincovf ${params.mtbseq_mincovf} --mincovr ${params.mtbseq_mincovr} --minphred ${params.mtbseq_minphred} --minfreq ${params.mtbseq_minfreq}"

        """
        mkdir Called

        ${params.mtbseq_path} --step TBvariants \\
            --threads ${task.cpus} \\
            --project ${params.mtbseq_project} \\
            --resilist ${ref_resistance_list} \\
            --intregions ${ref_interesting_regions} \\
            --categories ${ref_gene_categories} \\
            --basecalib ${ref_base_quality_recalibration} \\
            ${args} \\
        1>>.command.out \\
        2>>.command.err \\
        || true               # NOTE This is a hack to overcome the exit status 1 thrown by mtbseq

        """

    stub:

        """
        sleep \$[ ( \$RANDOM % 10 )  + 1 ]s

        echo "${params.mtbseq_path} --step TBvariants \
            --threads ${task.cpus} \
            --project ${params.mtbseq_project} \
            --mincovf ${params.mtbseq_mincovf} \
            --mincovr ${params.mtbseq_mincovr} \
            --minphred ${params.mtbseq_minphred} \
            --minfreq ${params.mtbseq_minfreq} \
            --resilist ${ref_resistance_list} \
            --intregions ${ref_interesting_regions} \
            --categories ${ref_gene_categories} \
            --basecalib ${ref_base_quality_recalibration}"


        mkdir Called
        touch Called/${meta.id}_${meta.library}.gatk_position_uncovered_cf${params.mtbseq_mincovf}_cr${params.mtbseq_mincovr}_fr${params.mtbseq_minfreq}_ph${params.mtbseq_minphred}_outmode000.tab
        touch Called/${meta.id}_${meta.library}.gatk_position_variants_cf${params.mtbseq_mincovf}_cr${params.mtbseq_mincovr}_fr${params.mtbseq_minfreq}_ph${params.mtbseq_minphred}_outmode000.tab

        """

}

process TBJOIN {
    tag "cohort"
    label 'process_high_memory'

    conda "bioconda::mtbseq=1.1.0"


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mtbseq:1.1.0--hdfd78af_0' :
        'biocontainers/mtbseq:1.1.0--hdfd78af_0' }"



    input:
        path("Called/*")
        path("Position_Tables/*")
        path(samplesheet_tsv)
        env(USER)
        tuple path(ref_resistance_list), path(ref_interesting_regions), path(ref_gene_categories), path(ref_base_quality_recalibration)

    output:
        path("Joint/${params.mtbseq_project}_joint*samples*.{tab,log}")
        path("Joint/${params.mtbseq_project}_joint*samples*.tab"), emit: joint_samples

    script:
        def args = task.ext.args ?: " --project ${params.mtbseq_project} --mincovf ${params.mtbseq_mincovf} --mincovr ${params.mtbseq_mincovr} --minphred ${params.mtbseq_minphred} --minfreq ${params.mtbseq_minfreq} --distance ${params.mtbseq_distance}"
        """
        mkdir Joint

        ${params.mtbseq_path} --step TBjoin \\
            --threads ${task.cpus} \\
            --samples ${samplesheet_tsv} \\
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

        echo "${params.mtbseq_path} --step TBjoin \
            --threads ${task.cpus} \
            --samples ${samplesheet_tsv} \
            --project ${params.mtbseq_project} \
            --mincovf ${params.mtbseq_mincovf} \
            --mincovr ${params.mtbseq_mincovr} \
            --minphred ${params.mtbseq_minphred} \
            --minfreq ${params.mtbseq_minfreq} \
            --resilist ${ref_resistance_list} \
            --intregions ${ref_interesting_regions} \
            --categories ${ref_gene_categories} \
            --basecalib ${ref_base_quality_recalibration}"


        mkdir Joint
        touch Joint/${params.mtbseq_project}_joint_cf${params.mtbseq_mincovf}_cr${params.mtbseq_mincovr}_fr${params.mtbseq_minfreq}_ph${params.mtbseq_minphred}_samples5.tab
        touch Joint/${params.mtbseq_project}_joint_cf${params.mtbseq_mincovf}_cr${params.mtbseq_mincovr}_fr${params.mtbseq_minfreq}_ph${params.mtbseq_minphred}_samples5.log

        """

}

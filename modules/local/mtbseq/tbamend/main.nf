process TBAMEND {
    tag "cohort"
    label 'process_single'

    conda "bioconda::mtbseq=1.1.0"


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mtbseq:1.1.0--hdfd78af_0' :
        'biocontainers/mtbseq:1.1.0--hdfd78af_0' }"

    input:
        path("Joint/*")
        path(samplesheet_tsv)
        env(USER)
        tuple path(ref_resistance_list), path(ref_interesting_regions), path(ref_gene_categories), path(ref_base_quality_recalibration)

    output:
        path("Amend/*"), emit: samples_amended

    script:

    def args = task.ext.args ?: "--project ${params.mtbseq_project} --mincovf ${params.mtbseq_mincovf} --mincovr ${params.mtbseq_mincovr} --minphred ${params.mtbseq_minphred} --minfreq ${params.mtbseq_minfreq} --unambig ${params.mtbseq_unambig} --window ${params.mtbseq_window} --distance ${params.mtbseq_distance}"

        """
        mkdir Amend

        ${params.mtbseq_path} --step TBamend \\
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

        echo " ${params.mtbseq_path} --step TBamend \
            --threads ${task.cpus} \
            --samples ${samplesheet_tsv} \
            --project ${params.mtbseq_project} \
            --mincovf ${params.mtbseq_mincovf} \
            --mincovr ${params.mtbseq_mincovr} \
            --minphred ${params.mtbseq_minphred} \
            --minfreq ${params.mtbseq_minfreq} \
            --unambig ${params.mtbseq_unambig} \
            --window ${params.mtbseq_window} \
            --distance ${params.mtbseq_distance} \
            --resilist ${ref_resistance_list} \
            --intregions ${ref_interesting_regions} \
            --categories ${ref_gene_categories} \
            --basecalib ${ref_base_quality_recalibration}  "


        mkdir Amend
        touch Amend/${params.mtbseq_project}_joint_cf${params.mtbseq_mincovf}_cr${params.mtbseq_mincovr}_fr${params.mtbseq_minfreq}_ph${params.mtbseq_minphred}_samples5_amended.tab
        touch Amend/${params.mtbseq_project}_joint_cf${params.mtbseq_mincovf}_cr${params.mtbseq_mincovr}_fr${params.mtbseq_minfreq}_ph${params.mtbseq_minphred}_samples5_amended_u95_phylo.tab
        touch Amend/${params.mtbseq_project}_joint_cf${params.mtbseq_mincovf}_cr${params.mtbseq_mincovr}_fr${params.mtbseq_minfreq}_ph${params.mtbseq_minphred}_samples5_amended_u95_phylo.fasta
        touch Amend/${params.mtbseq_project}_joint_cf${params.mtbseq_mincovf}_cr${params.mtbseq_mincovr}_fr${params.mtbseq_minfreq}_ph${params.mtbseq_minphred}_samples5_amended_u95_phylo.plainIDs.fasta
        touch Amend/${params.mtbseq_project}_joint_cf${params.mtbseq_mincovf}_cr${params.mtbseq_mincovr}_fr${params.mtbseq_minfreq}_ph${params.mtbseq_minphred}_samples5_amended_u95_phylo_w12.tab
        touch Amend/${params.mtbseq_project}_joint_cf${params.mtbseq_mincovf}_cr${params.mtbseq_mincovr}_fr${params.mtbseq_minfreq}_ph${params.mtbseq_minphred}_samples5_amended_u95_phylo_w12.fasta
        touch Amend/${params.mtbseq_project}_joint_cf${params.mtbseq_mincovf}_cr${params.mtbseq_mincovr}_fr${params.mtbseq_minfreq}_ph${params.mtbseq_minphred}_samples5_amended_u95_phylo_w12.plainIDs.fasta
        touch Amend/${params.mtbseq_project}_joint_cf${params.mtbseq_mincovf}_cr${params.mtbseq_mincovr}_fr${params.mtbseq_minfreq}_ph${params.mtbseq_minphred}_samples5_amended_u95_phylo_w12_removed.tab

        """

}

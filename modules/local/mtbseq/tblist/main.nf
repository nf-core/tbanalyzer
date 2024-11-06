process TBLIST {
    tag "${meta.id}"
    label 'process_single_high_memory'

    conda "bioconda::mtbseq=1.1.0"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mtbseq:1.1.0--hdfd78af_0' :
        'biocontainers/mtbseq:1.1.0--hdfd78af_0' }"


    input:
        tuple val(meta), path("Mpileup/${meta.id}_${meta.library}*.gatk.mpileup")
        env(USER)
        tuple path(ref_resistance_list), path(ref_interesting_regions), path(ref_gene_categories), path(ref_base_quality_recalibration)

    output:
        path("Position_Tables/${meta.id}_${meta.library}*.gatk_position_table.tab"), emit: tbjoin_input
        tuple val(meta), path("Position_Tables/${meta.id}_${meta.library}*.gatk_position_table.tab"), emit: position_table_tuple
        path("Position_Tables/${meta.id}_${meta.library}*.gatk_position_table.tab"), emit: position_table

    script:
        def args = task.ext.args ?: "--minbqual ${params.mtbseq_minbqual}"
        """
        mkdir Position_Tables

        ${params.mtbseq_path} --step TBlist \\
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

        echo "${params.mtbseq_path} --step TBlist \
            --threads ${task.cpus} \
            --project ${params.mtbseq_project} \
            --minbqual ${params.mtbseq_minbqual} \
            --resilist ${ref_resistance_list} \
            --intregions ${ref_interesting_regions} \
            --categories ${ref_gene_categories} \
            --basecalib ${ref_base_quality_recalibration}"


        touch ${task.process}_${meta.id}_out.log
        touch ${task.process}_${meta.id}_err.log

        mkdir Position_Tables
        touch Position_Tables/${meta.id}_${meta.library}.gatk_position_table.tab

        """

}

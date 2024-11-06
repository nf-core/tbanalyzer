process TBPILE {
    tag "${meta.id}"
    label 'process_single'
    stageInMode 'copy'

    conda "bioconda::mtbseq=1.1.0"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mtbseq:1.1.0--hdfd78af_0' :
        'biocontainers/mtbseq:1.1.0--hdfd78af_0' }"



    input:
        tuple val(meta), path("GATK_Bam/*")
        env(USER)
        tuple path(ref_resistance_list), path(ref_interesting_regions), path(ref_gene_categories), path(ref_base_quality_recalibration)

    output:
        path("Mpileup/${meta.id}_${meta.library}*.gatk.{mpileup,mpileuplog}")
        tuple val(meta), path("Mpileup/${meta.id}_${meta.library}*.gatk.mpileup"), emit: mpileup

    script:

        """
        mkdir Mpileup

        ${params.mtbseq_path} --step TBpile \\
            --threads ${task.cpus} \\
            --project ${params.mtbseq_project} \\
            --resilist ${ref_resistance_list} \\
            --intregions ${ref_interesting_regions} \\
            --categories ${ref_gene_categories} \\
            --basecalib ${ref_base_quality_recalibration} \\
        1>>.command.out \\
        2>>.command.err \\
        || true               # NOTE This is a hack to overcome the exit status 1 thrown by mtbseq

        """

    stub:

        """
        echo "${params.mtbseq_path} --step TBpile \
            --threads ${task.cpus} \
            --project ${params.mtbseq_project} \
            --resilist ${ref_resistance_list} \
            --intregions ${ref_interesting_regions} \
            --categories ${ref_gene_categories} \
            --basecalib ${ref_base_quality_recalibration}"

        sleep \$[ ( \$RANDOM % 10 )  + 1 ]s

        mkdir Mpileup
        touch Mpileup/${meta.id}_${meta.library}.gatk.mpileup
        touch Mpileup/${meta.id}_${meta.library}.gatk.mpileuplog

        """

}

process TBREFINE {
    tag "${meta.id}"
    label 'process_medium'

    conda "bioconda::mtbseq=1.1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mtbseq:1.1.0--hdfd78af_0' :
        'biocontainers/mtbseq:1.1.0--hdfd78af_0' }"



    input:
        tuple val(meta), path("Bam/")
        env(USER)
        tuple path(ref_resistance_list), path(ref_interesting_regions), path(ref_gene_categories), path(ref_base_quality_recalibration)

    output:
        tuple val(meta), path("GATK_Bam/${meta.id}_${meta.library}*gatk.{bam,bai,bamlog,grp,intervals}"), emit: gatk_bam

    script:

        """
        mkdir GATK_Bam

        ${params.mtbseq_path} --step TBrefine \\
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
        sleep \$[ ( \$RANDOM % 10 )  + 1 ]s

        echo " ${params.mtbseq_path} --step TBrefine \
            --threads ${task.cpus} \
            --project ${params.mtbseq_project} \
            --resilist ${ref_resistance_list} \
            --intregions ${ref_interesting_regions} \
            --categories ${ref_gene_categories} \
            --basecalib ${ref_base_quality_recalibration}"


        mkdir GATK_Bam
        touch GATK_Bam/${meta.id}_${meta.library}.gatk.bam
        touch GATK_Bam/${meta.id}_${meta.library}.gatk.bai
        touch GATK_Bam/${meta.id}_${meta.library}.gatk.bamlog
        touch GATK_Bam/${meta.id}_${meta.library}.gatk.grp
        touch GATK_Bam/${meta.id}_${meta.library}.gatk.intervals
        """
}

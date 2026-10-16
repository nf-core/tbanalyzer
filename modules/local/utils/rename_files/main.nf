process RENAME_FILES {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mtbseq:1.1.0--hdfd78af_0' :
        'biocontainers/mtbseq:1.1.0--hdfd78af_0' }"

    input:
        tuple val(meta), path(reads)

    output:
        path("${meta.id}_${meta.library}_R?.fastq.gz")                 , emit: files
        tuple val(meta), path("${meta.id}_${meta.library}_R?.fastq.gz"), emit: meta_and_files

    script:
        """
        echo "Renaming ${reads} files as per MTBseq requirements."

        cp ${reads[0]} ${meta.id}_${meta.library}_R1.fastq.gz
        cp ${reads[1]} ${meta.id}_${meta.library}_R2.fastq.gz
        """

    stub:
        """
        touch ${meta.id}_${meta.library}_R1.fastq.gz
        touch ${meta.id}_${meta.library}_R2.fastq.gz
        """
}

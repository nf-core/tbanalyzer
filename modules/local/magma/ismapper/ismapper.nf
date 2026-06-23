process ISMAPPER {
    tag "${meta.id}"
    label 'process_medium'

    input:
        tuple val(meta), path(reads)
        path(ref_gbk)
        path(ref_fasta)
        path(query_multifasta)

    output:
        tuple val(meta), path("*.ismapper.vcf"), emit: formatted_vcf
        tuple val(meta), path("ismapper"),       emit: results_dir

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    ismap \\
        --t ${task.cpus} \\
        --output_dir ${meta.id} \\
        --queries ${query_multifasta} \\
        --reference ${ref_gbk} \\
        --reads ${reads}

    mkdir ismapper
    mv ${meta.id}/*/* ismapper/

    convert_ismapper_to_vcf.py \\
        --is_mapper_dir ismapper/IS6110/ \\
        --reference_file ${ref_fasta} \\
        --query_file ${query_multifasta} \\
        --output_vcf_file ${meta.id}.ismapper.vcf
    """

    stub:
    """
    touch ${meta.id}.ismapper.vcf
    mkdir ismapper
    """
}

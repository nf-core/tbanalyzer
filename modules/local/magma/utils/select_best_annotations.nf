process UTILS_SELECT_BEST_ANNOTATIONS {
    tag "${joint_name}"
    label 'process_single'

    input:
        val(joint_name)
        path("annotations_and_tranches_json_files/*")
        path("recal_vcf_files/*")
        path("tranches_files/*")

    output:
        tuple val(joint_name), path("best_annotation_files/*.tbi"), path("best_annotation_files/*.recal.vcf.gz"), emit: bestRecalVcfTuple
        tuple val(joint_name), path("best_annotation_files/*.tranches"),                                          emit: bestTranchesFile
        path("all_annotations_data.json")

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir best_annotation_files
    select_best_annotations.py \\
        --input_directory annotations_and_tranches_json_files \\
        --output_directory best_annotation_files \\
        --output_json_file_name all_annotations_data.json
    """

    stub:
    """
    mkdir best_annotation_files
    touch all_annotations_data.json
    """
}

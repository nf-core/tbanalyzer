process UTILS_CAT_SPOTYPING {
    label 'process_single'

    input:
        path("results_text/*")

    output:
        path("*.cat.txt")
        path("results_text")

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    cat results_text/*txt >> spotyping.cat.txt
    """

    stub:
    """
    touch spotyping.cat.txt
    """
}

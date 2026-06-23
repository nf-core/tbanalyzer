process FASTQ_VALIDATOR {
    tag "${meta.id}"
    label 'process_low'

    input:
        tuple val(meta), path(sampleRead)
        val ready

    output:
        path("*.fastq_report.csv"),              emit: fastq_report
        tuple val(meta), path(sampleRead),       emit: reads

    when:
    task.ext.when == null || task.ext.when

    shell:
    '''
    md5sum !{sampleRead} > !{sampleRead.simpleName}.md5sum_out.txt
    cat *md5sum_out.txt | csvtk space2tab | csvtk tab2csv | csvtk add-header -n md5sum,file > !{sampleRead.simpleName}.md5sum_stats.csv

    du -shL !{sampleRead} > !{sampleRead.simpleName}.du_out.txt
    cat *du_out.txt | csvtk tab2csv | csvtk add-header -n size,file > !{sampleRead.simpleName}.du_stats.csv

    csvtk join -f file \\
    !{sampleRead.simpleName}.md5sum_stats.csv \\
    !{sampleRead.simpleName}.du_stats.csv \\
    > !{sampleRead.simpleName}.du_md5sum_stats.csv

    rm *_out.txt !{sampleRead.simpleName}.du_stats.csv !{sampleRead.simpleName}.md5sum_stats.csv

    seqkit stats -a -T !{sampleRead} > !{sampleRead.simpleName}.seqkit_out.txt
    cat *seqkit_out.txt | csvtk space2tab | csvtk tab2csv > !{sampleRead.simpleName}.seqkit_stats.csv

    csvtk join -f file \\
    !{sampleRead.simpleName}.seqkit_stats.csv \\
    !{sampleRead.simpleName}.du_md5sum_stats.csv \\
    > !{sampleRead.simpleName}.fastq_statistics.csv

    rm *_out.txt

    fastq_validator.sh !{sampleRead} \\
    2>!{sampleRead.simpleName}.command.log || true

    cp !{sampleRead.simpleName}.command.log .command.log

    TEMP=$(tail -n 1 !{sampleRead.simpleName}.command.log)

    if [ "$(echo "$TEMP")" == "OK" ]; then
        STATUS="passed"
        echo -e "file,magma_name,fastq_utils_check" > !{sampleRead.simpleName}.check.${STATUS}.csv
        echo -e "!{sampleRead},!{meta.id},${STATUS}" >> !{sampleRead.simpleName}.check.${STATUS}.csv
        csvtk join -f file !{sampleRead.simpleName}.fastq_statistics.csv !{sampleRead.simpleName}.check.${STATUS}.csv > !{sampleRead.name}.fastq_report.csv
        rm !{sampleRead.simpleName}.fastq_statistics.csv
        exit 0
    else
        STATUS="failed"
        echo -e "file,magma_name,fastq_utils_check" > !{sampleRead.simpleName}.check.${STATUS}.csv
        echo -e "!{sampleRead},!{meta.id},${STATUS}" >> !{sampleRead.simpleName}.check.${STATUS}.csv
        csvtk join -f file !{sampleRead.simpleName}.fastq_statistics.csv !{sampleRead.simpleName}.check.${STATUS}.csv > !{sampleRead.name}.fastq_report.csv
        rm !{sampleRead.simpleName}.fastq_statistics.csv
        exit 1
    fi
    '''

    stub:
    """
    touch ${sampleRead.simpleName}.check.csv
    """
}

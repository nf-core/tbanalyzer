process LOFREQ_CALL_NTM {
    tag "${meta.id}"
    label 'process_medium'

    input:
        tuple val(meta), path(bamIndex), path(bam)
        path(reference)
        path("*")

    output:
        tuple val(meta), path("*.potential_NTM_fraction.txt"), emit: fraction

    when:
    task.ext.when == null || task.ext.when

    // Estimate non-tuberculous-mycobacteria (NTM) contamination: run LoFreq at
    // the 16S locus and sum the alternate-allele frequencies. Faithful port of
    // torch-magma modules/local/lofreq/call__ntm.nf — NOTE this is a distinct
    // computation from LOFREQ_CALL (which calls minor variants), not an alias.
    script:
    def args      = task.ext.args  ?: ''
    def region    = task.ext.args2 ?: ''
    def regionArg = region ? "-r ${reference.getBaseName()}:${region}" : ''
    """
    if [[ \$(lofreq call -f ${reference} ${regionArg} ${args} ${bam} | grep -v "#" | cut -f 2 -d ";" | tr -d 'AF=') ]]
    then
        lofreq call -f ${reference} ${regionArg} ${args} ${bam} | grep -v "#" | cut -f 2 -d ";" | tr -d 'AF=' | awk '{Total=Total+\$1} END{print Total}' > ${meta.id}.potential_NTM_fraction.txt
    else
        echo "0" > ${meta.id}.potential_NTM_fraction.txt
    fi
    """

    stub:
    """
    touch ${meta.id}.potential_NTM_fraction.txt
    """
}

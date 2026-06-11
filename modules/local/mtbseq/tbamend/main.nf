process TBAMEND {
    tag "cohort"
    label 'process_single'

    conda "${moduleDir}/environment.yml"


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

    def args = task.ext.args ?: "--project mtbseqnf --mincovf 4 --mincovr 4 --minphred 4 --minfreq 75 --unambig 95 --window 12 --distance 12"

        """
        mkdir Amend

        MTBseq --step TBamend \\
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

        echo " MTBseq --step TBamend \
            --threads ${task.cpus} \
            --samples ${samplesheet_tsv} \
            --project mtbseqnf \
            --mincovf 4 \
            --mincovr 4 \
            --minphred 4 \
            --minfreq 75 \
            --unambig 95 \
            --window 12 \
            --distance 12 \
            --resilist ${ref_resistance_list} \
            --intregions ${ref_interesting_regions} \
            --categories ${ref_gene_categories} \
            --basecalib ${ref_base_quality_recalibration}  "


        mkdir Amend
        touch Amend/mtbseqnf_joint_cf4_cr4_fr75_ph4_samples5_amended.tab
        touch Amend/mtbseqnf_joint_cf4_cr4_fr75_ph4_samples5_amended_u95_phylo.tab
        touch Amend/mtbseqnf_joint_cf4_cr4_fr75_ph4_samples5_amended_u95_phylo.fasta
        touch Amend/mtbseqnf_joint_cf4_cr4_fr75_ph4_samples5_amended_u95_phylo.plainIDs.fasta
        touch Amend/mtbseqnf_joint_cf4_cr4_fr75_ph4_samples5_amended_u95_phylo_w12.tab
        touch Amend/mtbseqnf_joint_cf4_cr4_fr75_ph4_samples5_amended_u95_phylo_w12.fasta
        touch Amend/mtbseqnf_joint_cf4_cr4_fr75_ph4_samples5_amended_u95_phylo_w12.plainIDs.fasta
        touch Amend/mtbseqnf_joint_cf4_cr4_fr75_ph4_samples5_amended_u95_phylo_w12_removed.tab

        """

}

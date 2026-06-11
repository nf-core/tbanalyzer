process TBFULL {
    tag "cohort"
    label 'process_tbfull'
    label 'error_retry'


    conda "${moduleDir}/environment.yml"


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mtbseq:1.1.0--hdfd78af_0' :
        'biocontainers/mtbseq:1.1.0--hdfd78af_0' }"



    input:
        path("*")
        env(USER)
        tuple path(ref_resistance_list), path(ref_interesting_regions), path(ref_gene_categories), path(ref_base_quality_recalibration)

    output:
        path("Called")
        path("Position_Tables")
        path("Classification")
        path("Statistics")
        path("Statistics/Mapping_and_Variant_Statistics.tab"), emit: statistics
        path("Classification/Strain_Classification.tab"), emit: classification
        path("Called/*gatk_position_variants*.tab"), emit: position_variants
        path("Position_Tables/*.gatk_position_table.tab"), emit: position_tables
        path "versions.yml", emit: versions

    script:
        def args = task.ext.args ?: "--project mtbseqnf --minbqual 13 --mincovf 4 --mincovr 4 --minphred 4 --minfreq 75 --unambig 95 --window 12 --distance 12"

        """

        MTBseq --step TBfull \\
            --thread ${task.cpus} \\
            --intregions ${ref_interesting_regions} \\
            --categories ${ref_gene_categories} \\
            --basecalib ${ref_base_quality_recalibration} \\
            --resilist ${ref_resistance_list} \\
            ${args} \\
        1>>.command.out \\
        2>>.command.err \\
        || true               # NOTE This is a hack to overcome the exit status 1 thrown by mtbseq



       cat <<-END_VERSIONS > versions.yml
       "${task.process}":
          MTBseq: \$(MTBseq --version | cut -d " " -f 2)
       END_VERSIONS

        """

    stub:
        """
        sleep \$[ ( \$RANDOM % 10 )  + 1 ]s

        echo " MTBseq --step TBfull \
            --thread ${task.cpus} \
            --project mtbseqnf \
            --minbqual 13 \
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
            --basecalib ${ref_base_quality_recalibration} "


        mkdir GATK_Bam
        touch GATK_Bam/stub.gatk.bam
        touch GATK_Bam/stub.gatk.bai
        touch GATK_Bam/stub.gatk.bamlog
        touch GATK_Bam/stub.gatk.grp
        touch GATK_Bam/stub.gatk.intervals
        mkdir Bam
        touch Bam/stub.bam
        touch Bam/stub.bai
        touch Bam/stub.bamlog
        mkdir Called
        touch Called/stub.gatk_position_uncovered_cf4_cr4_fr75_ph4_outmode000.tab
        touch Called/stub.gatk_position_variants_cf4_cr4_fr75_ph4_outmode000.tab
        mkdir Mpileup
        touch Mpileup/stub.gatk.mpileup
        touch Mpileup/stub.gatk.mpileuplog
        mkdir Classification
        touch Classification/Strain_Classification.tab
        mkdir Position_Tables
        touch Position_Tables/stub.gatk_position_table.tab
        mkdir Statistics
        touch Statistics/Mapping_and_Variant_Statistics.tab

        printf '"%s":\\n    MTBseq: 1.1.0\\n' "${task.process}" > versions.yml

        """

}

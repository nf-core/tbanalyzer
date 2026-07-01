process GATK_VARIANT_RECALIBRATOR {
    tag "mode: ${analysisMode} ann: ${annotations}"
    label 'process_high'

    input:
        val(analysisMode)
        val(annotations)
        tuple val(meta), path(variantsIndex), path(variantsVcf)
        val(resourceFilesArg)
        path(resourceFiles)
        path(resourceFileIndexes)
        path(reference)
        path("*")

    output:
        tuple val(meta), path("*.tbi"), path("*.recal.vcf.gz"),              emit: recalVcfTuple
        tuple val(meta), path("*.tranches"),                                  emit: tranchesFile
        path("*.R")
        path("*.model")
        path("*.pdf"), optional: true
        tuple val(meta), path("*${analysisMode}*.command.log"),              emit: annotationsLog

    when:
    task.ext.when == null || task.ext.when

    script:
    def args                   = task.ext.args ?: ''
    def finalResourceFilesArg  = resourceFilesArg ? "--resource:${resourceFilesArg}" : ""
    def annotationSuffix       = task.ext.prefix ? ".${task.ext.prefix}" : ""
    def annLog                 = "${meta.id}.${analysisMode}${annotationSuffix}.command.log"
    // Retry-safe: nf-nomad's wrapper runs the script under `bash -C` (noclobber).
    // A leftover ${annLog} from a prior attempt would make `gatk ... 2>${annLog}`
    // exit 1 before gatk runs (`cannot overwrite existing file`). Pre-delete the
    // file so retries are well-behaved. (${annLog} is captured as an output for
    // UTILS_ELIMINATE_ANNOTATION to read gatk's stderr.)
    """
    rm -f ${annLog}

    gatk VariantRecalibrator --java-options "-Xmx${task.memory.giga}G" \\
        -R ${reference} \\
        -V ${variantsVcf} \\
        ${finalResourceFilesArg} \\
        ${annotations} \\
        ${args} \\
        -mode ${analysisMode} \\
        --tranches-file ${meta.id}.${analysisMode}${annotationSuffix}.tranches \\
        --rscript-file ${meta.id}.${analysisMode}${annotationSuffix}.R \\
        --output ${meta.id}.${analysisMode}${annotationSuffix}.recal.vcf.gz \\
        --output-model ${meta.id}.${analysisMode}${annotationSuffix}.model \\
        2>${annLog}

    cp ${annLog} .command.log
    """

    stub:
    """
    touch ${meta.id}.${analysisMode}.tranches
    touch ${meta.id}.${analysisMode}.R
    touch ${meta.id}.${analysisMode}.recal.vcf.gz
    touch ${meta.id}.${analysisMode}.model
    touch ${meta.id}.${analysisMode}.command.log
    """
}

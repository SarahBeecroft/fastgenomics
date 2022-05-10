params.outputDir=workflow.workDir + '/../outputs'
params.saveMode = "link"
params.bwaThreads = 12
params.bamsorTMP = "./"
params.groupTupleSize = 3

saveMode = params.saveMode

bamsorThreads=Math.min(12,params.bwaThreads)

bamsorTMP=params.bamsorTMP

intervalOrderFile=file(params.refdir+'/interval_lists.17/interval_list.order')
intervalOrder=intervalOrderFile.readLines()
intervalCount=intervalOrderFile.countLines()

inputFile = file(params.inputFile)

lines = inputFile.readLines()

println "============================================================"
println "Project : $workflow.projectDir"
println "Git info: $workflow.repository - $workflow.revision [$workflow.commitId]"
println "Cmd line: $workflow.commandLine"
println "Config  : $workflow.configFiles"
println "============================================================"

process AlignAndSort {
    input:
    each line from lines

    output:
    set val(sampleID),file("large_files/${output_bam_basename}.bam"),file("large_files/${output_bam_basename}.bam.bai") into AlignAndSortOutChannel
    set val(fastq1),val(fastq2) into CompressFastqInChannel

    script:
    list = line.split('\t')
    sampleID = list[0]
    fastq1 = list[1]
    fastq2 = list[2]
    index  = list[3]
    output_bam_basename = "${sampleID}.dedup.${index}.sorted"
    metrics_filename="${output_bam_basename}.bam.dupmetrics"
    """
    mkdir large_files
    lfs setstripe -c 25 -S 4M large_files
    bwa mem \
        -t ${task.cpus} \
        -R @RG\\\\tID:"${sampleID}"\\\\tLB:None\\\\tPL:ILLUMINA\\\\tPU:NA\\\\tSM:"${sampleID}" \
        -v 3 -Y \$ref_fasta \
        ${fastq1} ${fastq2} 2> >(tee ${output_bam_basename}.bwa.stderr.log >&2) | \
    \${bamsorpath}/bamsormadup \
        threads=${bamsorThreads} \
        inputformat=sam \
        outputformat=bam \
        reference=\${ref_fasta} \
        tmpfile=${bamsorTMP}/${sampleID}/${output_bam_basename} \
        fragmergepar=${bamsorThreads} \
        M=${metrics_filename} \
        indexfilename=large_files/${output_bam_basename}.bam.bai \
        optminpixeldif=2500 \
        O=large_files/${output_bam_basename}.bam > large_files/${output_bam_basename}.bam
    """

}

AlignAndSortOutChannel.groupTuple(size:params.groupTupleSize).set{MergeBAMsInChannel}

process MergeBAMs {
    publishDir "${params.outputDir}/${sampleID}/", mode: "${saveMode}", pattern: "*.dedup.merged.sorted.hs38.bam*"

    input:
    set val(sampleID), file(input_bams), file(input_bais) from MergeBAMsInChannel

    output:
    set val(sampleID),file("${output_bam}"),file("${output_bam}.bai") into HaplotypeCallerInChannel

    script:
    output_bam="${sampleID}.dedup.merged.sorted.hs38.bam"
    """
    sambamba merge -t ${task.cpus} ${output_bam} \$(echo $input_bams | tr '\n' ' ')
    """
}

process HaplotypeCaller {

    input:
    set val(sampleID), file(input_bam), file(input_bai) from HaplotypeCallerInChannel
    each interval from intervalOrder

    output:
    set val(sampleID), file("${sampleID}*.g.vcf.gz"), file("${sampleID}*.vcf.gz.tbi") into HaplotypeCallerOutChannel

    script:
    gvcf_basename = "${sampleID}.${interval}.g.vcf.gz"
    """
    gatk --java-options "-Xmx8000m -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -XX:ParallelGCThreads=2" \
        HaplotypeCaller \
        -R \${ref_fasta} \
        -I ${input_bam} \
        -L \${refdir}/interval_lists.17/${interval} \
        -O ${gvcf_basename} \
        -G StandardAnnotation -G StandardHCAnnotation -G AS_StandardAnnotation \
        -stand-call-conf 15.0 \
        -GQB 5 -GQB 10 -GQB 15 -GQB 20 -GQB 30 -GQB 40 -GQB 50 -GQB 60 \
        -ERC GVCF

    """
}

HaplotypeCallerOutChannel.groupTuple(size:(int)(intervalCount)).set{MergeVCFsInChannel}

process MergeVCFs {
    publishDir "${params.outputDir}/${sampleID}/", mode: "${saveMode}", pattern: "*.hs38.g.vcf.gz*"

    input:
    set val(sampleID), file(input_gvcfs),file(input_tbis) from MergeVCFsInChannel

    output:
    set val(sampleID),file("${output_vcf_name}"),file("${output_vcf_name}.tbi") into MergeVCFsOutChannel

    script:
    output_vcf_name = "${sampleID}.hc.merged.hs38.g.vcf.gz"
    """
    java -Xmx8000m -XX:ParallelGCThreads=2 -jar ${picardpath}/picard.jar \
        MergeVcfs \
        INPUT=\$(echo "${input_gvcfs}" | sed 's/ /\\n/g' | sort | tr '\\n' ' ' | sed 's/ / INPUT= /g' | sed 's/ INPUT= \$//' ) \
        OUTPUT=${output_vcf_name}
    """
}

/*
process GenotypeVCFs {
    publishDir "${params.outputDir}/${sampleID}/", mode: "${saveMode}", pattern: "*.hc.merged.hs38.vcf.gz"

    input:
    set val(sampleID),file(input_gvcf),file(input_tbi) from MergeVCFsOutChannel

    script:
    output_vcf_name = "${sampleID}.hc.merged.hs38.vcf.gz"
    """
    gatk --java-options "-Xmx8000m -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -XX:ParallelGCThreads=2" \
        GenotypeGVCFs \
        -R \${ref_fasta} \
        -V ${input_gvcf} \
        -O ${output_vcf_name}
    """
}
*/

process CompressFastq {
    input:
    set val(fastq1),val(fastq2) from CompressFastqInChannel
    
    script:
    """
    echo ${fastq1}
    echo ${fastq2}
    """
}


params.outputDir=workflow.workDir + '/../outputs'
params.saveMode = "link"
params.bwaThreads = 12
params.bamsorTMP = "./"
params.groupTupleSize = 3

saveMode = params.saveMode

bamsorThreads=Math.min(12,params.bwaThreads)
bamsorTMP=params.bamsorTMP

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
    set val(sampleID),file("${output_bam}"),file("${output_bam}.bai") into MergeBAMsOutChannel

    script:
    output_bam="${sampleID}.dedup.merged.sorted.hs38.bam"
    """
    sambamba merge -t ${task.cpus} ${output_bam} \$(echo $input_bams | tr '\n' ' ')
    """
}

process CompressFastq {
    input:
    set val(fastq1),val(fastq2) from CompressFastqInChannel

    script:
    """
    echo ${fastq1}
    echo ${fastq2}
    """
}

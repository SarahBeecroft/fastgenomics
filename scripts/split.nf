params.outputDir=workflow.workDir + '/../outputs'
params.saveMode = "link"
params.bwaThreads = 16
params.bamsorTMP = "./"

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


process SplitFastq {
    publishDir "${params.outputDir}/${sampleID}/", mode: "${saveMode}", pattern: "*.R*.fastq.gz"

    input:
    each line from lines
    output: 
    set val(sampleID),fastq1,fastq2 into CreateInputFileChannel

    script:
    list = line.split('\t')
    sampleID = list[0]
    fastq1 = list[1]
    fastq2 = list[2]
    """
    singularity exec \${SIFDIR}/fastqsplitter.sif fastqsplitter -i ${fastq1} \
        -o ${sampleID}_1.R1.fastq.gz \
        -o ${sampleID}_2.R1.fastq.gz \
        -o ${sampleID}_3.R1.fastq.gz &
    singularity exec \${SIFDIR}/fastqsplitter.sif fastqsplitter -i ${fastq2} \
        -o ${sampleID}_1.R2.fastq.gz \
        -o ${sampleID}_2.R2.fastq.gz \
        -o ${sampleID}_3.R2.fastq.gz &
    wait
    """
}
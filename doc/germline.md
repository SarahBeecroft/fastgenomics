# Preparing input files

The workflow takes as input a tab separated file with the following format

| Column | Field |
| ---    | ---     |
| 1      | SAMPLEID |
| 2      | Path to fastq1 |
| 3      | Path to fastq2 |
| 4      | FILEID (tumour only) |

The following is a valid input file for a tumour run. The last column is a unique identifier for the pair of reads. In this case it's taken from the filename though it could be any string.

    LKCGP-P002208-326284-01-03-01-R1	/scratch/df13/cci/LKCGP-P002208-326284-01-03-01-R1/HFT3LCCX2_1_210105_FD03061451_Homo-sapiens__R_160805_EMIMOU_LIONSDNA_M161_R1.fastq.gz	/scratch/df13/cci/LKCGP-P002208-326284-01-03-01-R1/HFT3LCCX2_1_210105_FD03061451_Homo-sapiens__R_160805_EMIMOU_LIONSDNA_M161_R2.fastq.gz	1
    LKCGP-P002208-326284-01-03-01-R1	/scratch/df13/cci/LKCGP-P002208-326284-01-03-01-R1/HFT3LCCX2_2_210105_FD03061451_Homo-sapiens__R_160805_EMIMOU_LIONSDNA_M161_R1.fastq.gz	/scratch/df13/cci/LKCGP-P002208-326284-01-03-01-R1/HFT3LCCX2_2_210105_FD03061451_Homo-sapiens__R_160805_EMIMOU_LIONSDNA_M161_R2.fastq.gz	2
    LKCGP-P002208-326284-01-03-01-R1	/scratch/df13/cci/LKCGP-P002208-326284-01-03-01-R1/HFT3LCCX2_4_210105_FD03061451_Homo-sapiens__R_160805_EMIMOU_LIONSDNA_M161_R1.fastq.gz	/scratch/df13/cci/LKCGP-P002208-326284-01-03-01-R1/HFT3LCCX2_4_210105_FD03061451_Homo-sapiens__R_160805_EMIMOU_LIONSDNA_M161_R2.fastq.gz	4

# Running the workflow

The workflows are intended to be run in 'local' mode where nextflow executes tasks on the same node that it is running on. 

## Germline workflow

The script below shows an example bash script for running the germline workflow. In this case all of the samples in `input.tsv` are processed on a single node. For the alignment step 12 threads are used, so a good fit is for 4 samples in `input.tsv`.

     #!/bin/bash
     #PBS -lwalltime=24:00:00
     #PBS -lmem=190G
     #PBS -lncpus=48
     #PBS -lstorage=scratch/df13
     #PBS -liointensive=1
     #PBS -ljobfs=400G
     #PBS -lwd
     #PBS -P df13
     #PBS -q normal
     #PBS -N germline.001

     module load nextflow/21.04.3
     tar xf /scratch/df13/processing/references/refgenome.tar -C ${PBS_JOBFS}

     NEXTFLOW_DIR=
     OUTPUT_DIR=

     nextflow run ${NEXTFLOW_DIR}/germline.nf \
        --refdir=${PBS_JOBFS}/cci \
        --inputFile=./germline.001.tsv \
        --bwaThreads=12 \
        --profile CCI \
        --with-timeline \
        --bamsorTMP="/iointensive/"
        --outputDir=${OUTPUT_DIR}

## Tumour workflow

The following is an example for running the tumour workflow on a sample with three sets of read pairs. This will run on a single node. 

     #!/bin/bash
     #PBS -lwalltime=24:00:00
     #PBS -lmem=190G
     #PBS -lncpus=48
     #PBS -lstorage=scratch/df13
     #PBS -liointensive=1
     #PBS -ljobfs=400G
     #PBS -lwd
     #PBS -P df13
     #PBS -q normal
     #PBS -N batch.001

     module load nextflow/21.04.3
     tar xf /scratch/df13/processing/references/refgenome.tar -C ${PBS_JOBFS}

     NEXTFLOW_DIR=
     OUTPUT_DIR=

     nextflow run ${NEXTFLOW_DIR}/tumour.nf \
        --refdir=${PBS_JOBFS}/cci \
        --inputFile=./input.001.tsv \
        --bwaThreads=16 \
        --profile CCI \
        --with-timeline \
        --bamsorTMP="/iointensive/" \
        --outputDir=${OUTPUT_DIR}

When the number of read pairs is different from 3, the `groupTupleSize` parameter can be used as below:

     #!/bin/bash
     #PBS -lwalltime=24:00:00
     #PBS -lmem=190G
     #PBS -lncpus=48
     #PBS -lstorage=scratch/df13
     #PBS -liointensive=1
     #PBS -ljobfs=400G
     #PBS -lwd
     #PBS -P df13
     #PBS -q normal
     #PBS -N batch.001

     module load nextflow/21.04.3
     tar xf /scratch/df13/processing/references/refgenome.tar -C ${PBS_JOBFS}

     NEXTFLOW_DIR=
     OUTPUT_DIR=

     nextflow run ${NEXTFLOW_DIR}/tumour.nf \
        --refdir=${PBS_JOBFS}/cci \
        --inputFile=./input.001.tsv \
        --bwaThreads=16 \
        --profile CCI \
        --with-timeline \
        **--groupTupleSize=4** \
        --bamsorTMP="/iointensive/" \
        --outputDir=${OUTPUT_DIR}

## Split tumour workflow

For cases where there is a single very large read pair, will need to split the file first. A script to do this is in progress.

# Software used

Will add final software list here.

| Software  | Version | Where         |
| ---       | ---     | ---           |
| bwa       | 0.7.17  | System module |
| sambamba  | 0.8.1   | System module |
| fastqsplitter | docker://pgc-images.sbgenomics.com/syan/fastqsplitter:production | Singularity container |
| biobambam2 | -  | compiled |

# 




#!/bin/bash
#PBS -lncpus=48
#PBS -lmem=190G
#PBS -ljobfs=400G
#PBS -lwalltime=24:00:00
#PBS -lstorage=scratch/df13
#PBS -liointensive=1
#PBS -lwd
#PBS -P fp0
#PBS -q normal
#PBS -N batch.tk
#PBS -W umask=022

module load nextflow/21.04.3

mkdir metrics
#start-sar.sh &

REFDIR=/scratch/df13/processing/references
NEXTFLOWDIR=/scratch/df13/processing/cci-nextflow

tar xf ${REFDIR}/refgenome.tar -C ${PBS_JOBFS}



nextflow run ${NEXTFLOWDIR}/nextflow/germline.nf \
         --refdir=${PBS_JOBFS}/cci \
         --inputFile=batch.tk.tsv \
         --bwaThreads=12 \
         -profile CCI \
         --outputDir=/scratch/df13/processing/tests/germline.100/outputs \
         -with-timeline \
         --bamsorTMP="/iointensive/"

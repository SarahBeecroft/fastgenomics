#!/bin/sh
# Creates a set of run directories and PBS scripts for the tumour workflow (3 pair inputs case)

for start in $(seq 1 3 75)
do
    end=$(($start + 2))
    batch=$(printf "%3.3d" $(($start / 3)))
    mkdir batch.$batch
    sed -n "${start},${end}p" < tumour.triples.tsv > batch.$batch/batch.$batch.tsv
    sed -e 's/tk/'${batch}'/'< tumour.template.sh > batch.$batch/submit.$batch.sh

done 


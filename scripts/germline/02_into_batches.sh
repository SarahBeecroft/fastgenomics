#!/bin/sh
#
# This script will create a set of directories for running the germline workflow.
# In each directory ther are two files:
#             - an input file containing 4 samples will be created based on a range of lines in randomised.tsv
#             - a PBS script based on `germline.template.sh`



shuf germline.input.tsv > randomised.tsv       # Probably not necessary
for start in $(seq 1 4 100)              # Sets the starting line to copy from randomised.tsv
do
    end=$(($start + 3))                  # Sets the last line to copy from randomised.tsv
    run=$(printf "%3.3d" $(($start / 4)))
    mkdir run.${run}
    sed -n "${start},${end}p" < randomised.tsv > run.${run}/run.${run}.tsv
    sed -e 's/tk/'${run}'/'< germline.template.sh > run.${run}/submit.${run}.sh

done 


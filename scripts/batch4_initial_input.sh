#!/bin/bash
# Nicely formatted directories get pushed into standard output
# Poorly formatted directories get pushed into standard error
for s in LKCGP*
do
    cd $s
    count=$(ls -1 *.fastq.gz | wc -l)
    if (( $count == 2))
    then
        R1=$(ls *R1.fastq.gz)
        R2=$(ls *R2.fastq.gz)
        printf "%s\t%s\t%s\n" $s ${PWD}/$R1 ${PWD}/$R2
    else
        echo $s >&2
    fi
    cd ..
done

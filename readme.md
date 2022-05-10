# Porting to Pawsey

Conda env to get around some missing local installs until containers or conda env built into pipeline
```
conda create -n mdnf
conda activate mdnf
mamba install -c bioconda nextflow=21.10.6 biobambam picard 
```

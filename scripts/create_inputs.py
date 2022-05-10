#!/usr/bin/env python3
import os
import sys
import glob

def pairwise(d):
    n = len(d)
    for i in range(n-1):
        for j in range(i+1,n):
            yield (d[i],d[j])

# Match up names of files within directory to get pairs of inputs
# Split filename on '_'.
# Assume come from same run if the first two strings are the same
# Assume lane ID comes from second string
def create_input_tumour(fh,baseDir,sample,files):
    # Compare all pairs of filenames
    for s1,s2 in pairwise(files):
        ss1 = s1.split('/')[-1].split('_')
        ss2 = s2.split('/')[-1].split('_')
        count = 0
        if(ss1[0]==ss2[0] and ss1[1]==ss2[1]):     ## First two fields identical
            if (ss1[-1] == "R1.fastq.gz"):
                firstRead = s1
                secondRead = s2
            else:
                firstRead = s2
                secondRead = s1
            lane = ss1[1]
            print('{}\t{}\t{}\t{}'.format(sample,
                                          firstRead,
                                          secondRead,
                                          lane),file=fh)

def create_pair(fh,baseDir,sample,files):
    ss1 = files[0].split('/')[-1].split('_')
    ss2 = files[1].split('/')[-1].split('_')
    if (ss1[1] == "R1.fastq.gz"):
        firstRead = files[0]
        secondRead = files[1]
    else:
        firstRead = files[1]
        secondRead = files[0]
    print('{}\t{}\t{}'.format(sample,
                              firstRead,
                              secondRead),file=fh)



# Very simple first pass through data
# Choose directories that
#      - Contain 6 input files
#      - Each input file is bigger than a threshold value
# OR
#      - Contain 2 input files
#      - Each input file is bigger than twice threshold value
def process_tumour_directory(baseDir,sample):
    thresh = 30000000000    # bytes    

    f = open('tumour.triples.tsv','a')
    g = open('tumour.singles.tsv','a')
    h = open('tumour.checks.tsv','a')
    l = open('tumour.log','a')

    files = os.listdir(baseDir+'/'+sample)
    files = glob.glob(baseDir+'/'+sample+'/*.fastq.gz')
    if(len(files)==6):
        count = 0
        for fname in files:
            stat = os.stat(fname)
            size = stat.st_size
            if (size > thresh):
                count = count + 1
        if (count == 6):
            create_input_tumour(f,baseDir,sample,files)
            print('triple\t{}'.format(sample),file=l)
        else:
            print('check\t{}'.format(sample),file=l)
            print('{}'.format(sample),file=h)
    elif(len(files)==2):
        count = 0
        for fname in files:
            stat = os.stat(fname)
            size = stat.st_size
            if (size > 2*thresh):
                count = count + 1
        if (count == 2):
            create_pair(g,baseDir,sample,files)
            print('single\t{}'.format(sample),file=l)
        else:
            print('check\t{}'.format(sample),file=l)
            print('{}'.format(sample),file=h)
    else:
        print('check\t{}'.format(sample),file=l)
        print('{}'.format(sample),file=h)
    f.close()
    g.close()
    h.close()
    l.close()
            
def process_germline_directory(baseDir,sample):
    thresh = 20000000000    # bytes
    f = open('germline.checks.tsv','a')
    g = open('germline.input.tsv','a')
    h = open('germline.log','a')
#    files = os.listdir(baseDir+'/'+sample)
    files = glob.glob(baseDir+'/'+sample+'/'+'*.fastq.gz')
    if(len(files)==2):
        count = 0
        for fname in files:
#            path = baseDir + '/' + sample + '/' + fname
            stat = os.stat(fname)
            size = stat.st_size
            if(size > thresh):
                count = count + 1
        if(count == 2):
            create_pair(g,baseDir,sample,files)
            print('normal\t{}'.format(sample),file=h)
        else:
            print('check\t{}'.format(sample),file=h)
            print('{}'.format(sample),file=f)
    else:
        print('{}'.format(sample),file=f)
        print('check\t{}'.format(sample),file=h)

# Only accept sample directories that begin 'LKC'
if __name__ == '__main__':

    if len(sys.argv) != 2:
        print("Call as {} <path-to-batch-folder>".format(sys.argv[0]))
        sys.exit(-1)

    baseDir = sys.argv[1]

    samples = os.listdir(baseDir)
    for sample in samples:
        if sample[0:3]=='LKC':
            s = sample.split('-')
            if (s[-1][0]=='G'):
                germline = True
                tumour = False
            else:
                germline = False
                tumour = True
            if tumour:
                process_tumour_directory(baseDir,sample)
                print('{}\ttumour'.format(sample))
            else:
                print('{}\tgermline'.format(sample))
                process_germline_directory(baseDir,sample)
        else:
            print('{}\tskip'.format(sample))
                        

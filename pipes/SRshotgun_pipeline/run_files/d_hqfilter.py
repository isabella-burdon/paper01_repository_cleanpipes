# import dependencies
import os
import numpy as np
import matplotlib.pyplot as plt
import string
import multiprocessing
from functools import partial

# get data paths
directory_path = 'b_readsDepleted'
output_path = 'd_hqfiltered'
samples = sorted([name for name in os.listdir(directory_path) if not name.startswith('.')])
sample_paths = [os.path.join(directory_path, x) for x in samples]


# define functions
def readFastq(filename):
    sequences = []
    qualities = []
    with open(filename) as fh:
        while True:
            fh.readline() # skip name line  **** RAISES ERROR
            seq = fh.readline().rstrip() # read base sequence, rstrip() removes the trailing newline character
            fh.readline() # skip placeholder line
            qual = fh.readline().rstrip() # base quality line
            if len(seq) == 0:
                break # break out of the loop if we are at the end of the file (number of lines left == 0)
            sequences.append(seq)
            qualities.append(qual)
    return sequences, qualities

def p33toQ(qual):
    return ord(qual) - 33

def findAverageQuality(qualities):
    avgQuals = []
    for qual in qualities:
        avgQuals.append(sum([p33toQ(x) for x in qual]) / len(qual))
    return avgQuals

def deplete_lowQualReads(lowQual_indices, input_file, output_file):
    with open(input_file, 'r') as fh_in, open(output_file, 'w') as fh_out:
        # Read all lines from the input file
        all_lines = fh_in.readlines()

        # Calculate the line numbers to exclude based on lowQual_indices
        excluded_line_numbers = [index * 4 + offset for index in lowQual_indices for offset in range(4)]

        # Write all lines to the output file except those that are in the excluded_line_numbers
        for line_number, line in enumerate(all_lines):
            if line_number not in excluded_line_numbers:
                fh_out.write(line)

# process
for sample in sample_paths:
    
    sample_name = os.path.basename(sample)

    seqs, quals = readFastq(sample) # raising error
    avgQuals = findAverageQuality(quals)

    lowQual_indices = []
    
    for i, read_qual in enumerate(avgQuals):
        if read_qual < 20:
            lowQual_indices.append(i)

    deplete_lowQualReads(lowQual_indices, sample, os.path.join(output_path, sample_name))
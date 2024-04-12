# mamba run -n SeqIO python run_files/d_hqfilter_SeqIO.py

# Import dependancies
import os
import numpy as np
from Bio import SeqIO

# get data paths
directory_path = 'b_readsDepleted'
output_path = 'd_hqfiltered'
samples = sorted([name for name in os.listdir(directory_path) if not name.startswith('.')])
sample_paths = [os.path.join(directory_path, x) for x in samples]

print(f"""Filtering {len(sample_paths)} samples
Samples to be filtered: {sample_paths}""")

# process
for sample_path in sample_paths:
    sample_name = os.path.basename(sample_path)
    output_file = os.path.join(output_path, sample_name)
    
    # Open input and output files
    with open(sample_path, "r") as input_handle, open(output_file, "w") as output_handle:
        # Iterate over records in the input FASTQ file and write filtered records to the output file
        for record in SeqIO.parse(input_handle, "fastq"):
            mean_quality = np.mean(record.letter_annotations['phred_quality'])
            if mean_quality >= 20:
                SeqIO.write(record, output_handle, "fastq")
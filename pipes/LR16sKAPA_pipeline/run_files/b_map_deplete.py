import os
import subprocess as sp
import gzip
import re
import json

# get data paths
input_data_directory = 'a_readsConcat'
output_data_directory = 'b_readsDepleted'
metrics_filepath = f"b_readMetrics/"
chm13_fasta_filepath = "b_contaminants/chm13.fasta"
lambda_fasta_filepath = "b_contaminants/phage_lambda.fasta"

# define functions
def count_fastq_reads(fastq_file):
    try:
        with gzip.open(fastq_file, 'rb') as f:
            line_count = sum(1 for line in f)
    except gzip.BadGzipFile:
        # If it's not a gzipped file, try opening it as a regular text file
        with open(fastq_file, 'r') as f:
            line_count = sum(1 for line in f)
    return line_count // 4  # Each read consists of 4 lines in a Fastq file

run_name_list = sorted([os.path.splitext(os.path.basename(file))[0].replace('.fastq', '').replace('.gz', '') for file in os.listdir(input_data_directory) if file.endswith('.fastq.gz')])

print(f"""
list of query fastq files: {run_name_list}""")

for run_name in run_name_list:
    print(f"""
    Running map_deplete.py on {run_name}:
    """)

    fastq_filepath = f"{input_data_directory}/{run_name}.fastq.gz"
    output_filepath = f"{output_data_directory}/{run_name}"

    # Run minimap2 and samtools commands to deplete lambda reads
    command_map_lambda = f"minimap2 -t 4 -ax map-ont {lambda_fasta_filepath} {fastq_filepath} | samtools view -f 4 -b -o {output_filepath}_lambda.bam && samtools fastq -f 4 -0 {output_filepath}_lambda.fastq {output_filepath}_lambda.bam"

    print(f"""
            Depleting phage lambda reads... 
            """)
        
    try:
        lambda_process = sp.run(command_map_lambda, shell=True, check=True, stderr=sp.PIPE, text=True)
        lambda_minimap2_report = lambda_process.stderr
        print(f"""
            Phage lambda reads depleted. 
            Moving on to depletion of chm13 reads...
            """)
    except sp.CalledProcessError:
        print("An error occurred during processing. Please check your inputs and dependencies.")

    command_map_chm13 = f"minimap2 -t 4 -ax map-ont {chm13_fasta_filepath} {output_filepath}_lambda.fastq | samtools view -f 4 -b -o {output_filepath}_chm13.bam && samtools fastq -f 4 -0 {output_filepath}_chm13.fastq {output_filepath}_chm13.bam"
        
    try:
        chm13_process = sp.run(command_map_chm13, shell=True, check=True, stderr=sp.PIPE, text=True)
        chm13_minimap2_report = chm13_process.stderr
        print(f"""
            chm13 reads depleted, processing complete. 
            Writing summary...""")
    except sp.CalledProcessError:
        print("An error occurred during processing. Please check your inputs and dependencies.")

    # write a summary report
    count_pre_depletion = count_fastq_reads(fastq_filepath)
    count_post_lambda_depletion = count_fastq_reads(f"{output_filepath}_lambda.fastq")
    count_post_chm13_depletion = count_fastq_reads(f"{output_filepath}_chm13.fastq")

    summary = f"""Summary stats for {run_name}:
        Significant reads (not host or lambda): {count_post_chm13_depletion}
        Total reads inc host (no lambda): {count_post_lambda_depletion}
        Proportion of reads mapped to chm13: {'N/A' if count_post_lambda_depletion == 0 else f'{round((count_post_lambda_depletion - count_post_chm13_depletion)/count_post_lambda_depletion*100, 2)}%'}
        Number of reads mapped to chm13 (and depleted): {count_post_lambda_depletion - count_post_chm13_depletion}
        Number of reads mapped to lambda phage (and depleted): {count_pre_depletion - count_post_lambda_depletion}

        Paths submitted to program:
            chm13 fasta reference genome path = {chm13_fasta_filepath}
            lambda phage fasta reference genome path ={lambda_fasta_filepath}
            Fastq reads file path = {fastq_filepath}
            Output file path = {output_filepath}

    Lambda depletion minimap2 generated report:
    {lambda_minimap2_report}

    chm13 depletion minimap2 generated report:
    {chm13_minimap2_report}
    """

    print(summary)

    summary_file_path = f"{metrics_filepath}/{run_name}_summary.txt"
    with open(summary_file_path, "w") as summary_file:
        summary_file.write(summary)

    print(f"""  Summary txt file written.
        Saved to: {metrics_filepath}/{run_name}_summary.txt""")

    # Append summary to summary_compiled.txt
    summary_path = f"{metrics_filepath}/{run_name}_summary.txt"
    if os.path.exists(summary_path):
        with open(f"{metrics_filepath}/summary_compiled.txt", "a") as summary_compiled:
            with open(summary_path, "r") as summary:
                first_7_lines = [next(summary) for _ in range(7)]
                summary_compiled.writelines(first_7_lines)
    else:
        print(f"""
              Summary file not found for {run_name}""")

    print(f"""
          
    **** Depletion of {run_name} complete! ****

    """)

# Read the input text file
with open(f'{metrics_filepath}/summary_compiled.txt', 'r') as file:
    content = file.read()

# Split the content into individual barcode sections
barcode_sections = re.split(r'\n\n', content.strip())

# Initialize an empty dictionary to store the results
result_dict = {}

# Process each barcode section
for section in barcode_sections:
    lines = section.split('\n')
    barcode = lines[0].split()[-1][:-1]

    # Extract summary stats for each barcode
    stats = {}
    for line in lines[1:]:
        key, value = line.split(':')
        stats[key.strip()] = value.strip()

    # Add the stats to the result dictionary
    result_dict[barcode] = stats

# Reorganize barcodes by alphanumeric order
result_dict_sorted = {k: result_dict[k] for k in sorted(result_dict)}

# Convert the dictionary to JSON format
json_data = json.dumps(result_dict_sorted, indent=4)

# Write the JSON data to a new file
with open(f'{metrics_filepath}/summary_metrics.json', 'w') as json_file:
    json_file.write(json_data)

print(f"Conversion completed. JSON file saved as 'summary_metrics.json' in '{metrics_filepath}' folder.")
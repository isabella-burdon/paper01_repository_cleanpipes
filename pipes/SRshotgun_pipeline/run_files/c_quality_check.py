import os
import shutil
import gzip
import subprocess

input_directory = 'b_readsDepleted'
output_directory = 'c_nanoQCinput'

# Ensure the output directory exists
os.makedirs(output_directory, exist_ok=True)

# List all files ending with '_chm13.fastq' in the input directory
input_files = sorted([f for f in os.listdir(input_directory) if f.endswith('_chm13.fastq')])

print(f"""
    files being processed: {input_files}...
    """)

# Process each file
for input_file in input_files:
    input_path = os.path.join(input_directory, input_file)

    # Remove '_chm13' from the filename
    output_file = os.path.splitext(input_file)[0].replace('_chm13', '') + '.fastq.gz'
    output_path = os.path.join(output_directory, output_file)

    # Print the file being converted
    print(f"Converting {input_file} to {output_file}")

    # Compress the file and move it to the output directory
    with open(input_path, 'rb') as f_in, gzip.open(output_path, 'wb') as f_out:
        shutil.copyfileobj(f_in, f_out)

print("""
fastq files are gzipped and ready for QC, files are stored in c_nanoQCinput.
      """)

print("""
Now running nanoQC on the files...
      """)

input_directory = "c_nanoQCInput"
output_directory = "c_QCMetrics"

# Ensure the output directory exists
os.makedirs(output_directory, exist_ok=True)

# Loop through all files in the input directory
for input_file in sorted(os.listdir(input_directory)):
    if input_file.endswith('.fastq.gz'):
        # Extract barcode from the file name and remove ".fastq" extension
        barcode = os.path.splitext(os.path.basename(input_file))[0].split('.')[0]

        # Run nanoQC command
        nanoQC_command = f'nanoQC -o "{os.path.join(output_directory, barcode)}" "{os.path.join(input_directory, input_file)}"'
        subprocess.run(nanoQC_command, shell=True)

print("""
    Processing complete
      """)
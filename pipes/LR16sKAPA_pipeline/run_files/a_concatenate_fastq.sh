#!/bin/bash

# Define the raw data directory
rawdata_directory="../../rawdata/BHI_LR16sKAPA_16082023"

# Define the output directory
output_directory="../../pipes/LR16sKAPA_pipeline/a_readsConcat"

# Go into the root directory
cd "$rawdata_directory" || exit 1

# Loop through each subdirectory in the raw data directory
for folder in */; do
    # Extract the folder name
    folder_name=$(basename "$folder")

    # Concatenate the files in the current folder and output to the specified directory
    cat "${rawdata_directory}/${folder_name}"/*.fastq.gz > "${output_directory}/${folder_name}.fastq.gz"
done

echo "Concatenation complete!"

# return to SRshotgun_pipeline directory
cd ../../pipes/LR16sKAPA_pipeline || exit 1

# to make executable: chmod +x run_files/a_concatenate_fastq.sh
# to run: ./run_files/a_concatenate_fastq.sh

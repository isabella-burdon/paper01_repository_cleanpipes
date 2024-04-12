#!/bin/bash

# Define the raw data directory
rawdata_directory="../../rawdata/AGRF_SRshotgun_22012024"

# Define the output directory
output_directory="../../pipes/SRshotgun_pipeline/a_readsConcat"

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
cd ../../pipes/SRshotgun_pipeline || exit 1

# to make executable: chmod +x concatenate_fastq.sh
# to run: ./concatenate_fastq.sh

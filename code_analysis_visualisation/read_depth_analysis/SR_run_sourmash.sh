# chmod +x SR_run_sourmash.sh
# ./SR_run_sourmash.sh

#!/bin/bash

# Directory paths
reads_dir="SR_shotgun_subsets"
output_dir="sourmash_output"
temp_dir="sourmash_tmp"
genome_db="../../genome_db/gtdb-rs214-k31.zip"
taxonomy_db="../../genome_db/gtdb-rs214.taxonomy.sqldb"

# Ensure the temporary directory exists
mkdir -p "$temp_dir"

# Iterate over sorted .fastq.gz files in reads_chopped_dir
for fastq_file in $(ls "$reads_dir"/*.fastq.gz | sort); do

    # Extract sample_name from the file name
    sample_name=$(basename "$fastq_file" | sed 's/\.fastq\.gz//')

    # Sketch
    sourmash sketch dna -p k=31,abund "$fastq_file" \
        -o "$temp_dir/$sample_name.sig.gz" --name "$sample_name"

    # Gather matches
    sourmash gather "$temp_dir/$sample_name.sig.gz" "$genome_db" --save-matches "$temp_dir/matches_$sample_name.zip"

    # Save gather results to CSV
    sourmash gather "$temp_dir/$sample_name.sig.gz" "$temp_dir/matches_$sample_name.zip" \
        -o "$temp_dir/$sample_name.gather.k31.gtdb.csv"

    # Tax metagenome to profile microbiome
    sourmash tax metagenome -g "$temp_dir/$sample_name.gather.k31.gtdb.csv" \
        -o "$output_dir/$sample_name.profile.csv" -t "$taxonomy_db" -F krona -r species

    # Print a message for each iteration
    echo "Processed $sample_name"

done

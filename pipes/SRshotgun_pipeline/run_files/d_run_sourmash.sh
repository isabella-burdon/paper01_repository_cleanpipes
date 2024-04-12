#!/bin/bash

# Directory paths
clean_reads_dir="d_hqfiltered"
output_dir="d_output"
temp_dir="d_tmp"
genome_db="../../genome_db/gtdb-rs214-k31.zip"
taxonomy_db="../../genome_db/gtdb-rs214.taxonomy.sqldb"

# Ensure the temporary directory exists
mkdir -p "$temp_dir"

# Iterate over sorted .fastq.gz files in clean_reads_dir
for fastq_file in $(ls "$clean_reads_dir"/*.fastq.gz | sort); do
    # Extract barcode from the file name
    barcode=$(basename "$fastq_file" | sed 's/\.fastq\.gz//')

    # Sketch
    sourmash sketch dna -p k=31,abund "$fastq_file" \
        -o "$temp_dir/$barcode.sig.gz" --name "$barcode"

    # Gather matches
    sourmash gather "$temp_dir/$barcode.sig.gz" "$genome_db" --save-matches "$temp_dir/matches_$barcode.zip"

    # Save gather results to CSV
    sourmash gather "$temp_dir/$barcode.sig.gz" "$temp_dir/matches_$barcode.zip" \
        -o "$temp_dir/$barcode.gather.k31.gtdb.csv"

    # Tax metagenome to profile microbiome
    sourmash tax metagenome -g "$temp_dir/$barcode.gather.k31.gtdb.csv" \
        -o "$output_dir/$barcode.profile.csv" -t "$taxonomy_db" -F krona -r species

    # Print a message for each iteration
    echo "Processed $barcode"
done

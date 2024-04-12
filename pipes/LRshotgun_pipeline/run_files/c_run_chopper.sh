
#!/bin/bash

# Directory paths
chopper_lengths_dir="c_qcmetrics/chopper_lengths"
nanoqc_input_dir="c_nanoQCinput"
output_dir="c_readsChopped"

# Iterate over sorted files in chopper_lengths_dir
for lengths_file in $(ls "$chopper_lengths_dir" | sort); do
    # Extract barcode from the file name
    barcode=$(basename "$lengths_file" | sed 's/_nanoQClengths\.txt//')

    # Read head_length and tail_length from the lengths file
    head_length=$(head -n 1 "$chopper_lengths_dir/$lengths_file")
    tail_length=$(sed -n '2p' "$chopper_lengths_dir/$lengths_file")

    # Construct the corresponding input fastq.gz file path
    input_fastq="$nanoqc_input_dir/$barcode.fastq.gz"

    # Construct the output file path
    output_fastq="$output_dir/$barcode.fastq.gz"

    # Run chopper with head_length and tail_length
    gunzip -c "$input_fastq" | chopper --headcrop "$head_length" --tailcrop "$tail_length" > "$output_fastq"

    # Print a message for each iteration
    echo "Processed $barcode"
done

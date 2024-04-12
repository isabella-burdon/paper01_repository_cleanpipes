#!/bin/bash
# before running please grant permission to execute the bash scripts:
# cd path to current directory/PAPER01/pipes/SRshotgun_pipeline
# chmod +x run_metapipe.sh
# to run: ./run_metapipe.sh

echo "Welcome to meta-pipe"

read -p "Is this your first time running meta-pipe? [y/n] " first_time

if [[ $first_time == "y" || $first_time == "Y" ]]; then
    read -p "Do you want to set up now (will install software and GTDB)? [y/n] " setup_now
    if [[ $setup_now == "y" || $setup_now == "Y" ]]; then
        ./setup.sh
    else
        echo "Running meta-pipe now..."
    fi

# run meta-pipe
elif [[ $first_time == "n" || $first_time == "N" ]]; then

    echo "Running meta-pipe now..."

    # grant execute permissions for bash scripts
    chmod +x run_files/a_concatenate_fastq.sh
    chmod +x run_files/c_run_chopper.sh
    chmod +x run_files/d_run_sourmash.sh

    # -- (1) concatenate raw reads
    ./run_files/a_concatenate_fastq.sh
    echo "Task 1/5 complete"

    # -- (2) deplete contaminant reads
    echo "Depleting contaminant reads..."
    mamba run -n minimap2 python run_files/b_map_deplete.py
    echo "Task 2/5 complete"

    # -- (3) drop low quality reads
    echo "Filtering out low quality reads..."
    mamba run -n SeqIO python run_files/d_hqfilter_SeqIO.py
    echo "Task 3/5 complete"

    # -- (4) gzip files for profiling
    echo "Compressing files for profiling..."
    gzip d_hqfiltered/*.fastq
    echo "Task 4/5 complete"

    # -- (4) get taxonomic profiles with sourmash (version 4.8.5, GTDB version 214)
    
    echo "Running sourmash... please be patient :)"
    mamba run -n smash ./run_files/d_run_sourmash.sh
    echo "Task 5/5 complete"

    echo "meta_pipe complete"
else
    echo "Please answer y/n. Exiting..."
fi

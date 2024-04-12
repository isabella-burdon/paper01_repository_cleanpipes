# #!/bin/bash

# download dependencies
echo "Downloading dependencies..."
pip install bs4 scipy pandas pyarrow matplotlib nanoQC bokeh==2.3.3
echo "Dependencies downloaded"

# create necessary environments
echo "Creating necessary environments..."
mamba create -y -c bioconda --platform osx-64 -n minimap2 minimap2 python
mamba create -y -c bioconda -n chopper chopper python pandas
mamba create -n smash -y -c conda-forge -c bioconda sourmash parallel python
echo "Environments created"

# set up database for sourmash
cd ../../genome_db
echo "Downloading GTDB database..."
wget https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/gtdb-rs214/gtdb-rs214-k31.zip
echo "Download complete"

echo "Summarizing GTDB database..."
mamba run -n smash sourmash sig summarize gtdb-rs214-k31.zip
echo "GTDB summarised"

echo "Downloading GTDB lineage csv"
wget https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/gtdb-rs214/gtdb-rs214.lineages.csv.gz
gunzip gtdb-rs214.lineages.csv.gz
echo "Download complete"

echo "Preparing sql database from GTDB and lineage csv..."
mamba run -n smash sourmash tax prepare -t gtdb-rs214.lineages.csv \
        -o gtdb-rs214.taxonomy.sqldb -F sql
echo "sql database prepared"

# if not errors then setup is complete
if [[ $? -eq 0 ]]; then
    echo "*** metapipe setup complete, ready to run ***"
fi
cd .. 
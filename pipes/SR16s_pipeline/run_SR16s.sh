# 16S Mock Community Short Read Analysis

# This contains the commands used to analyse the sinus mock community short read 16S dataset
# The analysis was run on a Linux Ubuntu 20.04 machine with 128GB RAM, Intel i9 with 16 cores (32 threads)
# The input path for qiime needs to be hardcoded, see manifest.txt file in SR16s_pipeline folder

# 1. Install qiime2 into a conda env

wget https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2023.9-py38-linux-conda.yml
mamba env create -n qiime2-amplicon-2023.9 --file qiime2-amplicon-2023.9-py38-linux-conda.yml
conda activate qiime2-amplicon-2023.9

# 2. Define output directory

OUTPUT_BASE="/home/user/Documents/qiime2/output"
mkdir -p $OUTPUT_BASE

# 3. Import and summarise the data

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path manifest.txt \
  --output-path $OUTPUT_BASE/paired-end-demux.qza \
  --input-format PairedEndFastqManifestPhred33V2

qiime demux summarize \
--i-data $OUTPUT_BASE/paired-end-demux.qza \
--o-visualization $OUTPUT_BASE/paired-end-demux.qzv


# 4. Dada2 denoising to create ASV feature table

# * The read qualities were very high across the reads - therefore, choose 300 as cutoff fwd, 275 as cuttoff rev

  qiime dada2 denoise-paired \
  --i-demultiplexed-seqs $OUTPUT_BASE/paired-end-demux.qza \
  --p-trim-left-f 0 \
  --p-trim-left-r 0 \
  --p-trunc-len-f 300 \ 
  --p-trunc-len-r 275 \
  --o-table $OUTPUT_BASE/dada2_table.qza \
  --o-representative-sequences $OUTPUT_BASE/dada2_rep_set.qza \
  --o-denoising-stats $OUTPUT_BASE/dada2_stats.qza \
  --p-n-threads 32

# 5. Table and summarise feature table

qiime feature-table summarize \
          --i-table $OUTPUT_BASE/dada2_table.qza \
          --o-visualization $OUTPUT_BASE/dada2_table.qzv 

# 6. Taxonomic analysis
# * This was run in 2 different ways - with Greengenes and Silva

## Greengenes
# * Download the classifier

wget \
  -O "gg-13-8-99-515-806-nb-classifier.qza" \
  "https://data.qiime2.org/2023.9/common/gg-13-8-99-515-806-nb-classifier.qza"

# * Run classification and tabulate
qiime feature-classifier classify-sklearn \
  --i-classifier gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads $OUTPUT_BASE/dada2_rep_set.qza \
  --o-classification $OUTPUT_BASE/taxonomy_gg.qza

qiime metadata tabulate \
  --m-input-file $OUTPUT_BASE/taxonomy_gg.qza \
  --o-visualization $OUTPUT_BASE/taxonomy_gg.qzv

qiime taxa barplot \
      --i-table $OUTPUT_BASE/dada2_table.qza \
      --i-taxonomy $OUTPUT_BASE/taxonomy_gg.qza \
      --m-metadata-file sample-metadata.tsv \
      --o-visualization $OUTPUT_BASE/taxa-bar-plots_gg.qzv


## Silva 
# * Download the classifier
wget \
  -O "silva-138-99-nb-classifier.qza" \
https://data.qiime2.org/2023.9/common/silva-138-99-nb-classifier.qza


# * Run classification and tabulate
qiime feature-classifier classify-sklearn \
  --i-classifier silva-138-99-nb-classifier.qza \
  --i-reads $OUTPUT_BASE/dada2_rep_set.qza \
  --o-classification $OUTPUT_BASE/taxonomy_silva.qza

qiime metadata tabulate \
  --m-input-file $OUTPUT_BASE/taxonomy_silva.qza \
  --o-visualization $OUTPUT_BASE/taxonomy_silva.qzv

qiime taxa barplot \
      --i-table $OUTPUT_BASE/dada2_table.qza \
      --i-taxonomy $OUTPUT_BASE/taxonomy_silva.qza \
      --m-metadata-file sample-metadata.tsv \
      --o-visualization $OUTPUT_BASE/taxa-bar-plots_silva.qzv

conda deactivate

#!/usr/bin/env bash

mamba create -n coatofarmsENV python=3.9
git clone https://github.com/gbouras13/coatofarms
cd coatofarms
conda activate coatofarmsENV
pip install -e .

DB_DIR="../../genomedb/emu_db"
THREADS=32

coatofarms download --database $DB_DIR
coatofarms run --input metadata_KAPA.csv --database $DB_DIR  --output KAPA_mock_out --threads $THREADS --conda-frontend mamba
conda deactivate

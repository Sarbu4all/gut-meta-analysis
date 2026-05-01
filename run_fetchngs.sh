#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define directories and paths
profile="docker"
SRA_IDS="sra-ids.csv"
DOWNLOADS_DIR="sra_downloads"
FETCHNGS_OUTDIR="${DOWNLOADS_DIR}/results"
SAMPLESHEET_IN="${FETCHNGS_OUTDIR}/samplesheet/samplesheet.csv"
SAMPLESHEET_OUT="samplesheet.csv"

echo ">>> Running nf-core/fetchngs..."
# Run fetchngs from the downloads directory
mkdir -p "${DOWNLOADS_DIR}"
cd "${DOWNLOADS_DIR}"
nextflow run nf-core/fetchngs -profile ${profile} --input "../${SRA_IDS}" --outdir "./results" "$@"
cd ..

echo ">>> Fixing samplesheet..."
# Run fix_samplesheet.py
python3 bin/fix_samplesheet.py "${SAMPLESHEET_IN}" "${FETCHNGS_OUTDIR}/fastq" "${SAMPLESHEET_OUT}"

echo ">>> Done! You can now run the pipeline with:"
echo "nextflow run . -profile ${profile} --input ${SAMPLESHEET_OUT} --outdir results"

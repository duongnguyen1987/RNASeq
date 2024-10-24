#!/bin/bash

#SBATCH --job-name=index_salmon
#SBATCH --time=00:30:00
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks=8

# Set variables
REFERENCE_DIR="/path/to/reference"
REFERENCE_GENOME="${REFERENCE_DIR}/OT3098.fasta.gz"  # Reference genome file
DECOYS_FILE="${REFERENCE_DIR}/decoys.txt"  # Decoys file
TRANSCRIPTOME="${REFERENCE_DIR}/PepsiCo_OT3098_V2_panoat_nomenclature_cDNA.fasta.gz"  # Transcriptome file
GENTROME="${REFERENCE_DIR}/gentrome.OT3098.nomenclature_cDNA.fa.gz"  # Concatenated gentrome file
SALMON_INDEX_DIR="/path/to/output/salmon_index"  # Output directory for Salmon index

# Create decoys file from reference genome
grep "^>" "${REFERENCE_GENOME}" | cut -d " " -f 1 > "${DECOYS_FILE}"
sed -i.bak 's/>//g' "${DECOYS_FILE}"

# Concatenate transcriptome and genome reference for Salmon index
cat "${TRANSCRIPTOME}" "${REFERENCE_GENOME}" > "${GENTROME}"

# Index the transcriptome using the decoy sequences
cd "/path/to/output/" || exit
salmon index -t "${GENTROME}" -d "${DECOYS_FILE}" -p 12 -i "${SALMON_INDEX_DIR}" --gencode --keepDuplicates

echo "Salmon index creation completed. Index saved in ${SALMON_INDEX_DIR}"

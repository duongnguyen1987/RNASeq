#!/bin/bash

#SBATCH --job-name=index_salmon
#SBATCH --time=00:30:00
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks=8


# Set variables
REFERENCE_DIR="../reference"
REFERENCE_GENOME="${REFERENCE_DIR}/OT3098_v2.fasta"
DECOYS_FILE="${REFERENCE_DIR}/decoys.txt"
TRANSCRIPTOME="${REFERENCE_DIR}/gentrome.OT3098.nomenclature_cDNA.fa.gz"
SALMON_INDEX_DIR="../salmon_nomenclature_cDNA/salmon_index"

# Create decoys file
grep "^>" "${REFERENCE_GENOME}" | cut -d " " -f 1 > "${DECOYS_FILE}"
sed -i.bak -e 's/>//g' "${DECOYS_FILE}"

# Index the transcriptome using the decoy sequences
cd ../salmon_nomenclature_cDNA/ || exit
salmon index -t "${TRANSCRIPTOME}" -d "${DECOYS_FILE}" -p 12 -i "${SALMON_INDEX_DIR}" --gencode --keepDuplicates

echo "Salmon index creation completed. Index saved in ${SALMON_INDEX_DIR}"

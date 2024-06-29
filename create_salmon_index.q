#!/bin/bash

#SBATCH --job-name=index_salmon
#SBATCH --time=00:30:00
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks=8


# Set variables
REFERENCE_DIR="/scratch3/ngu205/RNASeq_OCR/OT3098"
REFERENCE_GENOME="${REFERENCE_DIR}/OT3098.fasta.gz"
DECOYS_FILE="${REFERENCE_DIR}/decoys.txt"
TRANSCRIPTOME="${REFERENCE_DIR}/PepsiCo_OT3098_V2_panoat_nomenclature_cDNA.fasta.gz"
GENTROME="${REFERENCE_DIR}/gentrome.OT3098.nomenclature_cDNA.fa.gz"
SALMON_INDEX_DIR="../salmon_nomenclature_cDNA/salmon_index"

# Create decoys file
grep "^>" "${REFERENCE_GENOME}" | cut -d " " -f 1 > "${DECOYS_FILE}"
sed -i.bak 's/>//g' "${DECOYS_FILE}"

# Concatenate transcriptome and genome reference for Salmon index
cat "${TRANSCRIPTOME}" "${REFERENCE_GENOME}" > "${GENTROME}"

# Index the transcriptome using the decoy sequences
cd "../salmon_nomenclature_cDNA/" || exit
salmon index -t "${GENTROME}" -d "${DECOYS_FILE}" -p 12 -i "${SALMON_INDEX_DIR}" --gencode --keepDuplicates

echo "Salmon index creation completed. Index saved in ${SALMON_INDEX_DIR}"

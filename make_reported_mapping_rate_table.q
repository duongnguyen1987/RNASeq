#!/bin/bash

#SBATCH --job-name=Extract_ID_and_mapping_rate
#SBATCH --time=00:10:00
#SBATCH --mem=4G
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --account=YOUR_ACCOUNT_NAME

INPUT_FILE="/path/to/RNASeq_OCR/run2_analysis/hisat2_ISR/bam_mapping_rates.txt"
WORK_DIR="/path/to/RNASeq_OCR/run2_analysis/hisat2_ISR"

# Create output files with headers
# Extract total mapped reads
{
    echo -e "ID\tRead_mapped\tPercentage"
    paste -d '\t' <(grep "ID" "${INPUT_FILE}") <(grep "mapped" "${INPUT_FILE}" | grep -v -e "primary mapped" -e "mate mapped") | 
    awk 'BEGIN{OFS="\t"} {gsub(/\(/, "", $7); print $2, $3, $7}'
} > "${WORK_DIR}/hisat2_mapping_rate_total_mapped.txt"

# Extract primary mapped reads
{
    echo -e "ID\tRead_mapped\tPercentage"
    paste -d '\t' <(grep "ID" "${INPUT_FILE}") <(grep "primary mapped" "${INPUT_FILE}") | 
    awk 'BEGIN{OFS="\t"} {gsub(/\(/, "", $8); print $2, $3, $8}'
} > "${WORK_DIR}/hisat2_mapping_rate_primary_mapped.txt"

echo "Mapping rates extraction completed. Output files created in ${WORK_DIR}."

#!/bin/bash

#SBATCH --job-name=samtools_flagstat
#SBATCH --time=1:00:00
#SBATCH --mem=4G
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --account=YOUR_ACCOUNT_NAME
#SBATCH --array=1-275

# Load required modules
module load samtools/1.19.2 

# Directory paths
WORK_DIR="/path/to/RNASeq_OCR/run2_analysis/hisat2_ISR"
BAM_DIR="${WORK_DIR}/mapped"

cd "${BAM_DIR}"

# Create a list of BAM files
ls *.bam > bam_files_list.txt

# Ensure output file exists
OUTPUT_FILE="${WORK_DIR}/bam_mapping_rates.txt"
touch "${OUTPUT_FILE}"

# Get the base name for the current task
bam_file=$(sed -n ${SLURM_ARRAY_TASK_ID}p "${BAM_DIR}/bam_files_list.txt")
echo "Processing sample ${bam_file}"

# Extract the ID from the file name
id="${bam_file%.bam}"

# Use samtools flagstat to get mapping statistics and append to the output file
samtools flagstat "${BAM_DIR}/${bam_file}" >> "${OUTPUT_FILE}"

# Add the ID to the same line in the output file
echo -e "ID: ${id}" >> "${OUTPUT_FILE}"

# Add a separator line for clarity
echo "----------------------------------------" >> "${OUTPUT_FILE}"

echo "Completed processing for sample ${bam_file}. Results appended to ${OUTPUT_FILE}."

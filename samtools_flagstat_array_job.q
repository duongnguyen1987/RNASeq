#!/bin/bash

#SBATCH --job-name=samtools_flagstat
#SBATCH --time=1:00:00
#SBATCH --mem=4G
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --account=OD-221325
#SBATCH --array=1-275

# Load required modules
module load samtools/1.19.2 

# Directory paths
WORK_DIR="/datastore/ngu205/RNASeq_OCR/run2_analysis/hisat2_ISR"
BAM_DIR="${WORK_DIR}/mapped"

cd ${BAM_DIR}

# Make a list of bam file
ls *.bam > bam_files_list.txt

# Ensure output file exists
OUTPUT_FILE="${WORK_DIR}/bam_mapping_rates.txt"
touch "${OUTPUT_FILE}"

# Get the base name for the current task
bam_file=$(sed -n ${SLURM_ARRAY_TASK_ID}p ${BAM_DIR}/bam_files_list.txt)
echo "Processing sample ${bam_file}"

# Extract the ID from the file name
id="${bam_file%.bam}"

# Use samtools flagstat to get mapping statistics and append to the text file
samtools flagstat "${BAM_DIR}/${bam_file}" >> "${OUTPUT_FILE}"

# Add the ID to the same line in the text file
echo -e "ID: $id" >> "${OUTPUT_FILE}"

# Add a separator line for clarity
echo "----------------------------------------" >> "${OUTPUT_FILE}"


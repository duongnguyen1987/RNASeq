#!/bin/bash

#SBATCH --job-name=samtools_merge
#SBATCH --time=01:00:00
#SBATCH --mem=300G
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --account=your_account_name
#SBATCH --array=1-50

# Load required modules
module load samtools/1.19.2

# Directory paths
WORK_DIR="/path/to/RNASeq_OCR/bam_files"
OUT_DIR="/path/to/RNASeq_OCR/merged_infected_bams"

mkdir -p ${OUT_DIR}

cd ${WORK_DIR}

# Generate unique list of sample identifiers based on BAM files
ls *.bam | sed -E 's/_Infected[0-9]+\.bam$//' | sort -u > bam_file_list.txt

# Determine the current sample based on the SLURM_ARRAY_TASK_ID
current_sample=$(sed -n ${SLURM_ARRAY_TASK_ID}p bam_file_list.txt)

# Merge BAM files
samtools merge -@ ${SLURM_NTASKS} "${OUT_DIR}/${current_sample}_merged.bam" "${current_sample}_Infected1.bam" "${current_sample}_Infected2.bam" "${current_sample}_Infected3.bam"

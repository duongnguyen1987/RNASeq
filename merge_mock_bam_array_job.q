#!/bin/bash

#SBATCH --job-name=samtools_merge
#SBATCH --time=01:00:00
#SBATCH --mem=300G 
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --account=YOUR_ACCOUNT_NAME
#SBATCH --array=1-50

# Load required modules
module load samtools/1.19.2

# Directory paths
WORK_DIR="/path/to/RNASeq_OCR/bam_files"
OUT_DIR="/path/to/RNASeq_OCR/merged_mock_bams"

# Create output directory if it doesn't exist
mkdir -p "${OUT_DIR}"

cd "${WORK_DIR}"

# Generate unique list of sample identifiers based on BAM files in the working directory
ls *.bam | sed -E 's/_Mock[0-9]+\.bam$//; s/_Infected[0-9]+\.bam$//' | sort -u > bam_file_list.txt

# Determine the current sample based on the SLURM_ARRAY_TASK_ID
current_sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" bam_file_list.txt)

# Construct the full list of BAM files to merge
bam_files=("${current_sample}_Mock1.bam" "${current_sample}_Mock2.bam" "${current_sample}_Mock3.bam")

# Check if the BAM files exist before merging
for bam in "${bam_files[@]}"; do
    if [ ! -f "$bam" ]; then
        echo "Warning: $bam does not exist. Skipping..."
        exit 1
    fi
done

# Merge BAM files
samtools merge -@ "${SLURM_NTASKS}" "${OUT_DIR}/${current_sample}_merged.bam" "${bam_files[@]}"
echo "Merged BAM files for sample: ${current_sample}"

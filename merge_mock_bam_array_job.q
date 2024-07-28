#!/bin/bash

#SBATCH --job-name=samtools_merge
#SBATCH --time=01:00:00
#SBATCH --mem=300
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --account=OD-221325
#SBATCH --array=1-50

# Load required modules
module load samtools/1.19.2

Work_dir="/scratch3/ngu205/RNASeq_OCR/bam_files"
Out_dir="/scratch3/ngu205/RNASeq_OCR/merged_mock_bams"

mkdir -p ${Out_dir}

cd ${Work_dir}

# Generate unique list of sample identifiers based on BAM files in Out_dir
ls *.bam | sed -E 's/_Mock[0-9]+\.bam$//; s/_Infected[0-9]+\.bam$//' | sort -u > bam_file_list.txt

# Determine the current sample based on the SLURM_ARRAY_TASK_ID
current_sample=$(sed -n ${SLURM_ARRAY_TASK_ID}p ${Work_dir}/bam_file_list.txt)

# Merge BAM files
samtools merge -@ ${SLURM_NTASKS} "${Out_dir}/${current_sample}_merged.bam" "${current_sample}_Mock1.bam" "${current_sample}_Mock2.bam" "${current_sample}_Mock3.bam"

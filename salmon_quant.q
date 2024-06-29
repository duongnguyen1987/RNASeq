#!/bin/bash

# Usage: sbatch salmon_quant.q

#SBATCH --job-name=salmon_quant
#SBATCH --time=1:30:00
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --account=OD-221325
#SBATCH --array=1-275


module load salmon/1.10.1

# Directory paths
WORK_DIR="/scratch3/ngu205/RNASeq_OCR"
READS_DIR="${WORK_DIR}/fastp_result"
OUT_DIR="${WORK_DIR}/salmon/salmon_quant"
SALMON_INDEX="${WORK_DIR}/salmon/salmon_index"

# Create output directory if it doesn't exist
mkdir -p "${OUT_DIR}"

# Generate an array of unique sample names from the fastq.gz files
FILES=($(ls ${READS_DIR}/*R1_trimmed.fastq.gz | sed -e 's/_R1_trimmed.fastq.gz//g' | xargs -n 1 basename | sort -u))

# Get the base name for the current task
IN_FILE_BASE="${FILES[$SLURM_ARRAY_TASK_ID]}"
echo "Processing sample ${IN_FILE_BASE}"

# Define the input files
fastq1="${READS_DIR}/${IN_FILE_BASE}_R1_trimmed.fastq.gz"
fastq2="${READS_DIR}/${IN_FILE_BASE}_R2_trimmed.fastq.gz"

# Define the output directory for the current sample
quant_out="${OUT_DIR}/${IN_FILE_BASE}_quant"

# Run Salmon quantification
salmon quant -i ${SALMON_INDEX} -l A \
    -1 "${fastq1}" \
    -2 "${fastq2}" \
    -p ${SLURM_NTASKS} --validateMappings -o "${quant_out}"

echo "Salmon quantification completed for sample ${IN_FILE_BASE}"

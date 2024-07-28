#!/bin/bash

#SBATCH --job-name=samtools_index_csi
#SBATCH --time=1:00:00
#SBATCH --mem=4G
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --account=OD-221325
#SBATCH --array=1-275

# Load required modules
module load samtools/1.19.2 

# Directory paths
WORK_DIR="/datastore/ngu205/RNASeq_OCR/run2_analysis/hisat2_ISR/mapped/renamed_files/"
cd "${WORK_DIR}"

# Get the base name for the current task
bam_file=$(sed -n ${SLURM_ARRAY_TASK_ID}p ${WORK_DIR}/bam_files_list.txt)
echo "Processing sample ${bam_file}"

# Check if the corresponding index file does not exist
if [ ! -e "${bam_file}.csi" ]; then
    # Create the CSI index file
    samtools index -c "$bam_file"
    echo "CSI Index created for $bam_file"
else
    echo "CSI Index already exists for $bam_file"
fi
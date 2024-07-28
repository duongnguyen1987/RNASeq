#!/bin/bash

#SBATCH --job-name=rename_sorted_bam_files
#SBATCH --time=1:00:00
#SBATCH --mem=4G
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --account=OD-221325
#SBATCH --array=1-275

# Directory containing the files
input_dir="/datastore/ngu205/RNASeq_OCR/run2_analysis/hisat2_ISR/mapped"
output_dir="${input_dir}/renamed_files/"
cd mapped

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Path to the file containing the list of names
name_file="name_changed_list.txt"

# Read each line from the name file based on SLURM_ARRAY_TASK_ID
line=$(sed -n ${SLURM_ARRAY_TASK_ID}p "$name_file")
old_name=$(echo "$line" | awk '{print $1}')
new_name=$(echo "$line" | awk '{print $2}')

# Trim any leading or trailing whitespace from variables
old_name="${old_name%"${old_name##*[![:space:]]}"}"
new_name="${new_name%"${new_name##*[![:space:]]}"}"

# Copy the file to the new name in the output directory
cp "${input_dir}/${old_name}" "${output_dir}${new_name}"

# Print the new file name
echo "Renamed $old_name to $new_name"
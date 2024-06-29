#!/bin/bash

#SBATCH --job-name=vcf_to_hapmap
#SBATCH --time=01:00:00
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --account=OD-221325

# Define input and output directories
input_dir="./"

mkdir -p "$output_dir"
merged_dir="../run2_analysis/merged"
mkdir -p "$merged_dir"

# Step 1: Group files by sample name and merge lanes
declare -A r1_files
declare -A r2_files

# Loop through _R1 files and group them by sample name
for r1_file in "${input_dir}"*_R1_001.fastq.gz; do
    filename=$(basename "$r1_file")
    sample_name=$(echo "$filename" | cut -d_ -f1-4)
    lane=$(echo "$filename" | cut -d_ -f5)

    # Initialize arrays if not already
    r1_files["$sample_name"]+="$r1_file "
    r2_file="${input_dir}${sample_name}_${lane}_R2_001.fastq.gz"
    r2_files["$sample_name"]+="$r2_file "
done

# Step 2: Merge files for each sample
for sample_name in "${!r1_files[@]}"; do
    merged_r1="${merged_dir}/${sample_name}_R1_merged.fastq.gz"
    merged_r2="${merged_dir}/${sample_name}_R2_merged.fastq.gz"

    # Concatenate all R1 files for this sample
    cat ${r1_files["$sample_name"]} > "$merged_r1"
    
    # Concatenate all R2 files for this sample
    cat ${r2_files["$sample_name"]} > "$merged_r2"

    # Print a completion message for each sample
    echo "Merged files for ${sample_name}"
done

#!/bin/bash

#SBATCH --job-name=extract_raw_TPM_readcount
#SBATCH --time=00:30:00
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --account=OD-221325

# Define working directory
WORK_DIR="/scratch3/ngu205/RNASeq_OCR/salmon"
cd "${WORK_DIR}"

# Create directories for TPM and read count if they do not exist
mkdir -p TPM
mkdir -p readcount

# Extract TPM and read count data from quant.sf files
for dir in salmon_quant/*_quant; do
    # Extract the base name by removing the "_quant" suffix
    base=$(basename "$dir" "_quant")

    # Extract TPM values and save to TPM directory
    tpm_file="${base}_tpm.txt"
    awk '{print $1"\t"$4}' "$dir/quant.sf" > "TPM/$tpm_file"

    # Extract read count values and save to readcount directory
    readcount_file="${base}_readcount.txt"
    awk '{print $1"\t"$5}' "$dir/quant.sf" > "readcount/$readcount_file"
done


# Create a header for the merged TPM output file
echo -e "Name\t$(for file in TPM/*_tpm.txt; do base=$(basename "$file" "_tpm.txt"); echo -ne "${base}_tpm\t"; done)" > merged_tpm_combined.txt

# Merge TPM values from each sample into a single file
paste TPM/*_tpm.txt | awk 'NR==1{header=$1"\t"$3; for(i=5;i<=NF;i+=2) header=header"\t"$i; print header} NR>1{printf("%s\t%s\t", $1, $2); for(i=4;i<=NF;i+=2) printf("%s\t", $i); printf("\n");}' | tail -n +2 >> merged_tpm_combined.txt


# Create a header for the merged read count output file
echo -e "Name\t$(for file in readcount/*_readcount.txt; do base=$(basename "$file" "_readcount.txt"); echo -ne "${base}_NumReads\t"; done)" > merged_readcount_combined.txt

# Merge read count values from each sample into a single file
paste readcount/*_readcount.txt | awk 'NR==1{header=$1"\t"$3; for(i=5;i<=NF;i+=2) header=header"\t"$i; print header} NR>1{printf("%s\t%s\t", $1, $2); for(i=4;i<=NF;i+=2) printf("%s\t", $i); printf("\n");}' | tail -n +2 >> merged_readcount_combined.txt

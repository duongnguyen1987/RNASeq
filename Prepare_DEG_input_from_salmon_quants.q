#!/bin/bash

#SBATCH --job-name=prepare_DEA_input
#SBATCH --time=00:30:00
#SBATCH --mem=8G
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --account=OD-221325

# Define directories
WORK_DIR="/scratch3/ngu205/RNASeq_OCR/salmon"
QUANTS_DIR="${WORK_DIR}/salmon_quant"
SALMON_QUANT_DIR="${WORK_DIR}/salmon_quant_all"
RENAMED_DIR="${WORK_DIR}/renamed_quants"
NAME_FILE="${WORK_DIR}/name_changed_list.txt"

# Step 1: Copy quant.sf files with appropriate names to salmon_quant_all directory
echo "Copying quant.sf files to ${SALMON_QUANT_DIR}..."

# Change to the quants_PE directory
cd "${QUANTS_DIR}"

# Create the salmon_quant_all directory if it doesn't exist
mkdir -p "${SALMON_QUANT_DIR}"

# Loop through directories and copy quant.sf files
for dir in */; do
  dir=${dir%/}  # Remove the trailing slash
  if [ -f "$dir/quant.sf" ]; then
    cp "$dir/quant.sf" "${SALMON_QUANT_DIR}/${dir}.sf"
    echo "Copied $dir/quant.sf to ${SALMON_QUANT_DIR}/${dir}.sf"
  fi
done

echo "Completed copying quant.sf files."

# Step 2: Rename files based on the name_changed_list.txt
echo "Renaming files based on ${NAME_FILE}..."

# Create the renamed_quants directory if it doesn't exist
mkdir -p "${RENAMED_DIR}"

# Read each line from the name file and rename files
while IFS=$'\t' read -r old_name new_name; do
    # Trim any leading or trailing whitespace from variables
    old_name="${old_name%"${old_name##*[![:space:]]}"}"
    new_name="${new_name%"${new_name##*[![:space:]]}"}"

    # Copy the file to the new name in the renamed_quants directory
    cp "${SALMON_QUANT_DIR}/${old_name}.sf" "${RENAMED_DIR}/${new_name}.sf"
    echo "Renamed ${old_name}.sf to ${new_name}.sf"
done < "${NAME_FILE}"

echo "Completed renaming files."

echo "Preparation of input files for differential expression analysis is complete."

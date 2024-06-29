#!/bin/bash

#SBATCH --job-name=extract_mapping_rate_salmon
#SBATCH --time=00:30:00
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --account=OD-221325

WORK_DIR = "/scratch3/ngu205/RNASeq_OCR/salmon"

cd "${WORK_DIR}"

# Specify the parent directory containing the "_quant" subdirectories
parent_dir="salmon_quant"

# Specify the output file
output_file="salmon_mapping_rate.txt"

# Print header to the output file
echo -e "Sample ID\tMapping rate" > "$output_file"

# Loop through "_quant" subdirectories
for quant_dir in "$parent_dir"/*_quant; do
    # Extract the sample ID from the directory name
    sample_id="${quant_dir##*/}"

    # Define the path to the salmon_quant.log file
    log_file="$quant_dir/logs/salmon_quant.log"

    # Check if the log file exists
    if [ -f "$log_file" ]; then
        # Use grep and awk to extract the "Mapping rate" information
        mapping_rate=$(grep "Mapping rate" "$log_file" | awk '{print $NF}')
        
        # Print the result to the output file
        echo -e "$sample_id\t$mapping_rate" >> "$output_file"
    else
        echo "Error: $log_file does not exist."
    fi
done
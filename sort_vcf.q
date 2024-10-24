#!/bin/bash

#SBATCH --job-name=vcf_to_hapmap
#SBATCH --time=02:00:00
#SBATCH --mem=200G
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --account=your_account_name

# Load required modules
module load tassel/5.0

# Define variables

VCF_FILE="/path/to/vcf_file_bcf_bamlist/merged_mock_2.vcf"

# Sort VCF before convert
run_pipeline.pl -Xms4G -Xmx200G -SortGenotypeFilePlugin \
  -inputFile "$VCF_FILE" \
  -outputFile "${VCF_FILE%.vcf}.sorted.vcf" -fileType VCF

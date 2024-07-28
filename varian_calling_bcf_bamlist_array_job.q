#!/bin/bash

#SBATCH --job-name=variant_calling
#SBATCH --time=48:00:00
#SBATCH --mem=256G
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --account=OD-221325

# Load required modules
module load bcftools/1.20.0

# Define variables
REFERENCE_GENOME="/scratch3/ngu205/RNASeq_OCR/OT3098/PepsiCo_OT3098_V2_panoat_nomenclature.fasta"
BAM_FILES_DIR="/scratch3/ngu205/RNASeq_OCR/merged_mock_bams"
OUTPUT_DIR="/scratch3/ngu205/RNASeq_OCR/vcf_file_bcf_bamlist"
COMPRESSED_VCF="${OUTPUT_DIR}/merged_mock.vcf.gz"
BAM_LIST="${BAM_FILES_DIR}/bam_list.txt"

# Create output directory if it doesn't exist
mkdir -p ${OUTPUT_DIR}

# Generate a list of BAM files
ls ${BAM_FILES_DIR}/*.bam > ${BAM_LIST}

# Run bcftools mpileup and call using the BAM list
bcftools mpileup -a AD,DP,SP -Ou -I -f "${REFERENCE_GENOME}" -b "${BAM_LIST}" | \
bcftools call -a GQ,GP -mv -Oz -o "${COMPRESSED_VCF}"

# Compress and index the VCF file
bcftools index -c "${COMPRESSED_VCF}"

echo "Generated and indexed ${COMPRESSED_VCF}"


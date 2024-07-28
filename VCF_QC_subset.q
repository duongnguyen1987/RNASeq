#!/bin/bash

#SBATCH --job-name=VCF_QC
#SBATCH --time=0:30:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --account=OD-221325

module load vcflib/1.0.1 
module load vcftools/0.1.16
module load bcftools/1.20.0
module load htslib/1.9

# Declare variables

WORK_DIR="/scratch3/ngu205/RNASeq_OCR/vcf_file_bcf_bamlist/vcftool"
VCF_FILE="/scratch3/ngu205/RNASeq_OCR/vcf_file_bcf_bamlist/merged_infected.vcf.gz"
SUBSET_VCF=${WORK_DIR}/infected_bcf_subset.vcf
COMPRESSED_VCF=${WORK_DIR}/infected_bcf_subset.vcf.gz
OUT=${WORK_DIR}/infected_bcf_subset

# Create the directory if it doesn't exist
mkdir -p "$WORK_DIR"

bcftools view "${VCF_FILE}" | vcfrandomsample -r 0.012 > ${SUBSET_VCF}

# compress vcf
bgzip ${SUBSET_VCF}

# index vcf
bcftools index ${COMPRESSED_VCF}


# Calculate allele frequency
echo "Calculating allele frequency..."
vcftools --gzvcf $COMPRESSED_VCF --freq2 --out $OUT --max-alleles 2

# Calculate mean depth per individual
echo "Calculating mean depth per individual..."
vcftools --gzvcf $COMPRESSED_VCF --depth --out $OUT

# Calculate mean depth per site
echo "Calculating mean depth per site..."
vcftools --gzvcf $COMPRESSED_VCF --site-mean-depth --out $OUT

# Calculate site quality
echo "Calculating site quality..."
vcftools --gzvcf $COMPRESSED_VCF --site-quality --out $OUT

# Calculate proportion of missing data per individual
echo "Calculating proportion of missing data per individual..."
vcftools --gzvcf $COMPRESSED_VCF --missing-indv --out $OUT

# Calculate proportion of missing data per site
echo "Calculating proportion of missing data per site..."
vcftools --gzvcf $COMPRESSED_VCF --missing-site --out $OUT

# Calculate heterozygosity and inbreeding coefficient per individual
echo "Calculating heterozygosity and inbreeding coefficient per individual..."
vcftools --gzvcf $SUBSET_VCF --het --out $OUT

echo "All calculations are complete. Results are saved in ./vcftools."

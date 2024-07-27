#!/bin/bash

# Usage: sbatch hisat2_alignment.q

#SBATCH --job-name=hisat2_alignment
#SBATCH --time=1:30:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --account=OD-221325
#SBATCH --array=1-275

module load hisat/2.2.1
module load samtools/1.19.2

# Directory paths
WORK_DIR="/datastore/ngu205/RNASeq_OCR/run2_analysis/hisat2_ISR"
READS_DIR="/datastore/ngu205/RNASeq_OCR/run2_analysis/merged/trimming/fastp-results"
OUT_DIR="${WORK_DIR}/mapped"
SPLICE_SITE_FILE="${WORK_DIR}/splicesites.txt"
GENOME_INDEX="${WORK_DIR}/OT3098_v2_genome"

# Need to crete index for reference first
# hisat2-build -p 64 ../reference/OT3098_v2.fasta ./OT3098_v2_genome # This is prefer for hisat2

# Create output directory if it doesn't exist
mkdir -p "${OUT_DIR}"

# Get the base name for the current task
IN_FILE_BASE=$(sed -n ${SLURM_ARRAY_TASK_ID}p ${READS_DIR}/file_list.txt)
echo "Processing sample ${IN_FILE_BASE}"

# Define the input and output files
fastq1="${READS_DIR}/${IN_FILE_BASE}_R1_trimmed.fastq.gz"
fastq2="${READS_DIR}/${IN_FILE_BASE}_R2_trimmed.fastq.gz"
bam="${OUT_DIR}/${IN_FILE_BASE}.sorted.bam"

# Run HISAT2 to align the paired-end reads
hisat2 -p ${SLURM_NTASKS} \
       -x ${GENOME_INDEX} \
       -1 "$fastq1" \
       -2 "$fastq2" \
       --rna-strandness RF \
       --max-intronlen 10000 \
       --known-splicesite-infile ${SPLICE_SITE_FILE} \
    | samtools view -Sb | samtools sort -o "$bam"

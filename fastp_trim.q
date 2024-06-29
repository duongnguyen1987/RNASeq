#!/bin/bash

# Usage: sbatch fastp.q

#SBATCH --job-name=fastp
#SBATCH --time=0:30:00
#SBATCH --mem=4G
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --account=OD-221325
#SBATCH --array=1-275


module load fastp

#WORK_DIR="/scratch3/ident/Data"
# REALLY should be working in scratch3
WORK_DIR="/datastore/ngu205/RNASeq_OCR/run2_analysis/merged"
OUT_DIR="${WORK_DIR}/trimming/fastp-results"
READS_DIR="${WORK_DIR}/"
ADAP_DIR="${WORK_DIR}/Adapters"

# file_list.txt was created using - I'm sure there's better ways:
# ls -1 | sed -e 's/_R[12]_merged.fastq.gz//g' | sort | uniq > file_list.txt

IN_FILE_BASE=$(sed -n ${SLURM_ARRAY_TASK_ID}p ${READS_DIR}/file_list.txt)
echo ${IN_FILE_BASE}

fastp -i ${READS_DIR}/${IN_FILE_BASE}_R1_merged.fastq.gz -I ${READS_DIR}/${IN_FILE_BASE}_R2_merged.fastq.gz -o ${OUT_DIR}/${IN_FILE_BASE}_R1_trimmed.fastq.gz -O ${OUT_DIR}/${IN_FILE_BASE}_R2_trimmed.fastq.gz --thread ${SLURM_NTASKS} -q 15 -u 40 -y 30 -h ${OUT_DIR}/logs/${IN_FILE_BASE}.fastp.html -j ${OUT_DIR}/logs/${IN_FILE_BASE}.fastp.json



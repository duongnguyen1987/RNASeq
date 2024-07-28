# RNASeq Analysis

This repository contains scripts and resources for RNASeq analysis.

## Project Structure
### Prepare fastq file

- `merge_fastq_from_diff_lanes.q`: This was use to merge raw fastq files of same samples from different sequencing lanes
- `fastp_trim.q`: This was use to run slurm arrays to trim and clean the raw fastq files

### Use salmon to quantify the transcript in sample files - based on transciptome reference

- `create_salmon_index.q`: This was to create index file for salmon from reference genome and transcriptome
- `salmon_quant.q`: This was to run salmon on the trimmed fastq files to quantify the expression of transcripts
- `extract_salmon_mappingRate.q`: This was to extract mapping rate from all the samples after running salmon quantification
- `extract_raw_salmon_TPM_readcount`.q: This was to extract all the TPM and readcount value from individual files and merge in to two files
- `Prepare_DEG_input_from_salmon_quants.q`: This was to prepare the "quant" files from Salmon as input file to analyse in DEG package in R

### Use Hisat2 to map the transcript in sample files to reference genome

- `hisat2_alignment.q`: This was to map the fastq files to reference genomes and combine with samtools to generate the sorted bam files
- `samtools_flagstat_array_job.q`: This was to extract the mapping rates from individual bam files and merge into single files
- `make_reported_mapping_rate_table.q`: This was to make a table to report mapping rate from hisat2
- `rename_files_array_job.q`: This was to change the name of the sorted bam files. 
- `samtools_index_array_job.q`: This was to csi index all the sorted bam files so that it could be viewed in IGV app


- `results/`: Directory containing output files.

## Requirements

- List of required software and tools.
- Any other dependencies.

## Usage

Instructions on how to run the scripts, including any necessary commands or parameters.

## License

Information ab
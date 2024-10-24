### Installing Required R Packages

These commands install the necessary packages for RNA-seq differential expression analysis, visualization, and gene ontology enrichment:

```r
# Install Bioconductor packages for RNA-seq analysis
BiocManager::install("tximeta")          # Transcript quantification import
BiocManager::install("tximport")         # Efficient import of transcript data
BiocManager::install("DESeq2")           # Differential expression analysis
BiocManager::install("pheatmap")         # Heatmap visualization
BiocManager::install("apeglm")           # Shrinkage of log2 fold changes
BiocManager::install("EnhancedVolcano")  # Volcano plot visualization

# Install additional Bioconductor and CRAN packages for annotation and enrichment
BiocManager::install("AnnotationDbi")    # Database interface for biological annotations
BiocManager::install("limma")
BiocManager::install("VennDiagram")	 # Venn diagram visualization
          

# Install packages for GO term enrichment and co-expression clustering
BiocManager::install("Rgraphviz")        # Graph visualization using Graphviz
BiocManager::install("topGO")            # GO enrichment analysis
BiocManager::install("gprofiler2")       # GO term and pathway analysis
BiocManager::install("biomartr")         # Retrieve genomic data from repositories
BiocManager::install("clusterProfiler")  # Enrichment analysis
BiocManager::install("enrichplot")       # Visualization of enrichment results
BiocManager::install("GO.db")            # Gene Ontology annotations
```

### Loading Required Libraries

Before running your analysis, load the required libraries:

```r
# Load libraries for RNA-seq analysis and visualization
library(AnnotationDbi)
library(tximeta)
library(tximport)
library(DESeq2)
library(pheatmap)
library(apeglm)
library(EnhancedVolcano)
library(VennDiagram)
library(biomartr)
library(topGO)
library(Rgraphviz)
library(clusterProfiler)
library(enrichplot)


# Additional libraries for data manipulation and visualization
library(ggplot2)
library(magrittr)
library(dplyr)
library(tidyverse)
library(scales)
library(tibble)
library(stringr)
library(tidyr)
```

### RNA-seq Analysis Workflow

#### Set Working Directory and Prepare Metadata

Set your working directory to where the Salmon quantification files and related metadata are stored.

# Set working directory
setwd("/path/to/your/directory")  # Change to your directory

# Load sample metadata
coldata <- read.csv("sample_table.csv", row.names = 1, stringsAsFactors = TRUE)

# Add file paths for Salmon quantifications to coldata
coldata$names <- coldata$Run
coldata$files <- file.path("/path/to/salmon_quant", coldata$names, "quant.sf")  # Update path
file.exists(coldata$files)  # Check if all files exist


#### Import and Link Transcript Quantifications

Import the Salmon quantifications using `tximeta` and create a linked transcriptome for Avena sativa (oat):

# Load tximeta
library(tximeta)

# Define paths for index, FASTA files, and GTF annotations
indexDir <- file.path("/path/to/index")  # Update path
fastaFTP <- c("ftp://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-59/fasta/avena_sativa_ot3098/cdna/Avena_sativa_ot3098.Oat_OT3098_v2.cdna.all.fa.gz",
              "ftp://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-59/fasta/avena_sativa_ot3098/ncrna/Avena_sativa_ot3098.Oat_OT3098_v2.ncrna.fa.gz")
gtfPath <- file.path("/path/to/annotations", "annotations.gff3")  # Update path

# Link transcriptome to the imported quantifications
makeLinkedTxome(indexDir = indexDir,
                source = "Ensembl_FTP",
                organism = "Avena sativa",
                release = "2",
                genome = "Oat_OT3098_v2",
                fasta = fastaFTP,
                gtf = gtfPath,
                write = FALSE)

# Import the data using tximeta
se <- tximeta(coldata)

# Summarize to gene level
gse <- summarizeToGene(se, assignRanges = "abundant") # arguably will reflect more accurate genomic distances than the default option


#### Differential Expression Analysis

# You can now proceed to create the `DESeq2` dataset, apply pre-filtering, and run the differential expression analysis:

# Create DESeq2 dataset object
dds <- DESeqDataSet(gse, design = ~ Genotype + Genotype:Treatment)

# Pre-filter the dataset (remove genes with low counts)
smallestGroupSize <- 3
keep <- rowSums(counts(dds) >= 10) >= smallestGroupSize  # Genes with at least 10 counts in 3 samples
dds <- dds[keep,]

# Run the differential expression analysis
dds$Treatment <- relevel(dds$Treatment, ref = "Mock") # Set base level as Mock
dds <- DESeq(dds)
res <- results(dds)

# Save results
saveRDS(dds, file = "dds_results.rds")  # Update filename as needed

#### Visualize Results (PCA Plot and Sample Distances)

# Generate a PCA plot and hierarchical clustering heatmap for the sample distances:

# Variance stabilizing transformation
vsd <- vst(dds, blind = TRUE)

# Generate the PCA plot
plotPCA(vsd, intgroup = c("Genotype", "Treatment"))

# Plot PCA using ggplot2
pca_data <- plotPCA(vsd, intgroup = c("Genotype", "Treatment"), returnData = TRUE)
percent_var <- round(100 * attr(pca_data, "percentVar"), 2)
ggplot(pca_data, aes(x = PC1, y = PC2, color = Genotype, shape = Treatment)) +
  geom_point(size = 4) +
  ggtitle("PCA Plot") +
  labs(x = paste("PC1 (", percent_var[1], "%)", sep = ""),
       y = paste("PC2 (", percent_var[2], "%)", sep = "")) +
  theme_minimal()

# Sample distance matrix and heatmap
library("pheatmap")
library("RColorBrewer")

sampleDists <- dist(t(assay(vsd)))
sampleDistMatrix <- as.matrix(sampleDists)
pheatmap(sampleDistMatrix, fontsize_row = 5)


#### Log-Fold Change Shrinkage and Array Jobs

# Here is a script that automates the `lfcShrink` function using an array of coefficients:

# 1. **`process_lfcShrink.R`:** R script that processes the coefficients and applies `lfcShrink`:

#!/usr/bin/env Rscript

# Load required packages
library(DESeq2)
library(apeglm)

# Get the coefficient index from command line arguments
args <- commandArgs(trailingOnly = TRUE)
coef_index <- as.numeric(args[1])

# Load the DESeq2 object
dds <- readRDS("dds_results.rds")  # Update filename as needed

# Get list of coefficients with "TreatmentInfected"
all_coef_names <- resultsNames(dds)
coef_list <- all_coef_names[grep("TreatmentInfected", all_coef_names)]

# Check if index is valid
if (coef_index >= 1 && coef_index <= length(coef_list)) {
  coef_name <- coef_list[coef_index]
  
  # Apply lfcShrink and save results
  res <- lfcShrink(dds, coef = coef_name, type = "apeglm")
  write.csv(as.data.frame(res), file = paste0("res_", coef_name, ".csv"))
} else {
  stop("Invalid coefficient index.")
}


# 2. **`submit_lfcShrink_array.sh`:** SLURM script to submit array jobs in HPC Bash environment:

```bash
#!/bin/bash
#SBATCH --job-name=lfcShrink
#SBATCH --array=1-50  # Adjust based on the number of coefficients
#SBATCH --time=08:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --output=slurm-%A_%a.out
#SBATCH --error=slurm-%A_%a.err

module load R/4.3.1

# Run the R script with the array job index
Rscript process_lfcShrink.R $SLURM_ARRAY_TASK_ID
```

### Running the Analysis

# First, save the R script as `process_lfcShrink.R`.
# Then submit the SLURM job using `sbatch submit_lfcShrink_array.sh`.

# These steps will automate the log-fold change shrinkage for multiple genotypes.

### Save the output files of all the genotypes (infected vs Mock)

# Script to combine the results from all genotype tables into a single table
# with only the log2FoldChange, lfcSE, and padj columns

# Load necessary libraries (if not already loaded)
# library(dplyr)  # Uncomment if needed for data manipulation

# Get unique genotype names from colData
genotypes <- unique(coldata$Genotype)

# Initialize an empty data frame to store combined results
combined_results <- data.frame()

# Loop through each genotype and combine results
for (genotype in genotypes) {
  
  # Construct the file name for the current genotype results
  file_name <- paste0("res_Genotype", genotype, ".TreatmentInfected.csv")
  
  # Read the CSV file for the current genotype
  res <- read.csv(file_name)
  
  # Display column names for debugging purposes
  print(colnames(res))  # Helps to check if column names are as expected
  
  # Identify the gene identifier column (usually the first column)
  gene_column <- colnames(res)[1]
  
  # Select relevant columns: gene identifiers, log2FoldChange, lfcSE, and padj
  selected_data <- res[, c(gene_column, "log2FoldChange", "lfcSE", "padj")]
  
  # Rename log2FoldChange, lfcSE, and padj columns to include the genotype name
  colnames(selected_data)[2:4] <- paste0(genotype, "_", colnames(selected_data)[2:4])
  
  # Merge the selected data with the combined results
  if (nrow(combined_results) == 0) {
    combined_results <- selected_data
  } else {
    combined_results <- merge(combined_results, selected_data, by = gene_column, all = TRUE)
  }
}

# Save the combined results to a CSV file
output_file <- "combined_results_all_genotypes_tximeta.csv"
write.csv(combined_results, file = output_file, row.names = FALSE)

# Print completion message
cat("Combined results saved to:", output_file, "\n")

######## Comparison of gene regulation in Infect vs Mock in multiple genotypes ######

# Load necessary libraries
library(ggplot2)
library(dplyr)
library(tidyr)

# Read the CSV file
deg_data <- read.csv("combined_results_all_genotypes_tximeta.csv")

# Extract genotype names from column names
genotype_cols <- grep("_log2FoldChange$", colnames(deg_data), value = TRUE)
genotypes <- sub("_log2FoldChange$", "", genotype_cols)

# Create an empty data frame to store summary statistics
summary_table <- data.frame(Genotype = character(), Upregulated = integer(), Downregulated = integer())

# Iterate through each genotype
for (genotype in genotypes) {
  # Create column names for log2FoldChange and adjusted p-value
  log2fc_col <- paste0(genotype, "_log2FoldChange")
  padj_col <- paste0(genotype, "_padj")

  # Count upregulated genes
  upregulated_genes <- deg_data %>%
    filter(!!sym(log2fc_col) > 0.58, !!sym(padj_col) < 0.05) %>%
    nrow()

  # Count downregulated genes
  downregulated_genes <- deg_data %>%
    filter(!!sym(log2fc_col) < -0.58, !!sym(padj_col) < 0.05) %>%
    nrow()

  # Add counts to the summary table
  summary_table <- rbind(summary_table, data.frame(Genotype = genotype, Upregulated = upregulated_genes, Downregulated = downregulated_genes))
}

# Reshape the data for plotting
data_long <- summary_table %>%
  pivot_longer(cols = c(Upregulated, Downregulated),
               names_to = "Regulation",
               values_to = "Count") %>%
  mutate(Count = ifelse(Regulation == "Downregulated", -Count, Count))

# Create the bar chart
plot <- ggplot(data_long, aes(x = Genotype, y = Count, fill = Regulation)) +
  geom_bar(stat = "identity") +
  coord_flip() +  # Flips the coordinates to make bars horizontal
  scale_y_continuous(labels = abs, breaks = seq(-8500, 8500, by = 1000)) +  # Set axis steps of 1000
  scale_fill_manual(
    values = c("Downregulated" = "turquoise", "Upregulated" = "lightcoral"),
    labels = c("Downregulated Genes", "Upregulated Genes")  # Custom labels
  ) +
  labs(x = "Genotype", y = "Number of genes") +
  theme_minimal() +
  theme(
    panel.background = element_rect(fill = "white", color = NA),  # White background
    plot.background = element_rect(fill = "white", color = NA),   # White background
    panel.grid.major = element_line(color = "gray90"),  # Light grid lines
    panel.grid.minor = element_line(color = "gray95"),
    axis.text.y = element_text(size = 9),
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14),
    legend.position = "top",  # Move legend to the top
    legend.title = element_blank(),  # Remove the legend title
    legend.text = element_text(size = 12)
  )

# Save the plot
ggsave("gene_regulation_plot.png", plot = plot, width = 10, height = 6, dpi = 300)

######## Extract annotation information and combined with DEG data ############

library(dplyr)
library(tibble)
library(stringr)
library(tidyr)

# Read GFF3 file
gff3_file <- "PepsiCo_OT3098_V2_panoat_nomenclature_sorted.gff3"
gff_data <- read_delim(gff3_file, header = FALSE, comment.char = "#", sep = "\t", stringsAsFactors = FALSE)

# Save GFF3 data for later use (optional)
save(gff_data, file = "gff3_data.RData")

# Load GFF3 data from saved file (if needed)
# load("gff3_data.RData")

# Convert data frame to tibble
gff_data <- as_tibble(gff_data)

# Extract gene information from GFF3 data
gff_extracted <- gff_data %>%
  filter(grepl("gene", V3)) %>%
  mutate(GeneID = str_extract(V9, "(?<=ID=)[^;]+"),  # Extract Gene ID
         Chr = V1,  # Chromosome
         Start = V4,  # Start position
         End = V5,  # End position
         Alias = str_extract(V9, "(?<=Alias=)[^;]+"),  # Extract Alias
         Note = str_extract(V9, "(?<=Note=)[^;]+"),  # Extract Note
         Uniprot_id = str_extract(V9, "(?<=Uniprot_id=)[^;]+")) %>%  # Extract Uniprot ID
  select(GeneID, Chr, Start, End, Alias, Note, Uniprot_id) %>%
  # Replace NA values with empty strings
  mutate(across(c(Alias, Note, Uniprot_id), ~ replace_na(., "")))

# View the extracted data
print(gff_extracted)

# Save extracted data to CSV file
write.csv(gff_extracted, "gff_extracted.csv", row.names = FALSE)

# Load DEG data
deg_data <- read.csv(file.path("./tximeta_DEG", "combined_results_all_genotypes_tximeta.csv"))


# Convert the row names of deg_data to a column named 'GeneID'
colnames(deg_data)[1] <- "GeneID"

# Perform the join based on 'GeneID'
deg_data_gene_info <- inner_join(gff_extracted, deg_data, by = "GeneID")

# Print the combined data
print(deg_data_gene_info)

# Save tibble to CSV using write_csv
library(readr)
write_csv(deg_data_gene_info, "deg_data_tximeta_gene_info.csv")


####### Plot the DEG-count data for a single genotype using Volcano Plot  ############


# It reads the differential expression data from a CSV file and saves the plot as a PNG.

# Load necessary library
library(EnhancedVolcano)

# Define file paths and parameters as variables for easier reuse
input_file <- "deg_data_tximeta_gene_info.csv"  # Input CSV file
output_file <- "volcano_plot.png"               # Output PNG file

# Define the columns for log2 fold change and adjusted p-value
log2FC_col <- "X94197A1_9_2_2_2_5_log2FoldChange"
padj_col <- "X94197A1_9_2_2_2_5_padj"

# Define cutoff values for p-value and fold change
p_cutoff <- 0.05
FC_cutoff <- 0.58

# Plot title and legend labels
plot_title <- "2dpi versus mock \n (fold change cutoff = 0.58, p-value cutoff = 0.05)"
legend_labels <- c(
  'Not significant',
  'Log2 fold change (but do not pass p-value cutoff)',
  'Pass p-value cutoff',
  'Pass both p-value & Log2 fold change'
)

# Read the differential expression data from CSV
deg_data_gene_info <- read.csv(input_file)

# Open a PNG graphics device to save the plot
png(output_file, width = 1400, height = 600)

# Generate the volcano plot
EnhancedVolcano(
  toptable = deg_data_gene_info,
  x = log2FC_col,        # Column for log2 fold change
  y = padj_col,          # Column for adjusted p-value
  lab = rep("", nrow(deg_data_gene_info)),  # No labels for points
  xlim = c(-15, 15),     # Set x-axis limits
  ylim = c(0, 25),       # Set y-axis limits
  pCutoff = p_cutoff,    # p-value cutoff
  FCcutoff = FC_cutoff,  # Fold change cutoff
  pointSize = 2.0,       # Size of the points
  title = plot_title,    # Plot title
  legendLabels = legend_labels  # Custom legend labels
)

# Close the PNG graphics device
dev.off()

####### Create GO Database #######

# Extract GeneID and GO terms
gff_extracted_GO <- gff_data %>%
  filter(grepl("gene", V3)) %>%
  mutate(GeneID = str_extract(V9, "(?<=ID=)[^;]+"),
         GO_terms = str_extract(V9, "UniProt_GO=[^;]+")) %>%
  separate_rows(GO_terms, sep = "%2B") %>%
  mutate(GO_ID = str_extract(GO_terms, "GO:[0-9]+"),
         GO_Description = str_replace(GO_terms, "GO:[0-9]+\\^", ""),
         GO_Description = str_replace(GO_Description, "UniProt_GO=", ""),  # Remove UniProt_GO=
         GO_Description = str_replace(GO_Description, "\\^", " ")) %>%  # Replace ^ with space to make it readable
  select(GeneID, GO_ID, GO_Description) %>%
  drop_na()  # Remove rows with NA values

# Count unique GeneID values
gff_extracted_GO %>%
  summarize(UniqueGeneIDCount = n_distinct(GeneID))

# Separate GO_Description into GO_Type and GO_Description_Detail
gff_extracted_GO <- gff_extracted_GO %>%
  mutate(GO_Description = str_trim(GO_Description)) %>%  # Trim leading and trailing spaces
  mutate(GO_Type = str_extract(GO_Description, "^[^ ]+"),  # Extract text up to the first space
         GO_Detail = str_remove(GO_Description, "^[^ ]+ "))  # Remove the first part

# Print the updated data frame
print(gff_extracted_GO)

# Subset for 'cellular_component', 'biological_process', and 'molecular_function'
cellular_component_GO <- gff_extracted_GO %>%
  filter(GO_Type == "cellular_component")
biological_process_GO <- gff_extracted_GO %>%
  filter(GO_Type == "biological_process")
molecular_function_GO <- gff_extracted_GO %>%
  filter(GO_Type == "molecular_function")

# Write each subset to a CSV file
write.csv(cellular_component_GO, "cellular_component_GO.csv", row.names = FALSE)
write.csv(biological_process_GO, "biological_process_GO.csv", row.names = FALSE)
write.csv(molecular_function_GO, "molecular_function_GO.csv", row.names = FALSE)


##### topGO Enrichment Analysis for Gene Ontology #####

# Load necessary libraries
library(dplyr)
library(topGO)
library(Rgraphviz)

# Step 1: Load the Gene Ontology (GO) Data
# Read the GO terms for biological processes from a CSV file
biological_process_GO <- read.csv("biological_process_GO.csv")

# Extract the relevant columns: GeneID and GO_ID
biological_process_GO_subset <- biological_process_GO %>%
  dplyr::select(GeneID, GO_ID)

# Preview the first few rows
head(biological_process_GO_subset)

# Step 2: Prepare the gene2GO list
# Create a list where each element corresponds to a gene, and contains its associated GO terms
gene2GO <- tapply(biological_process_GO_subset$GO_ID, biological_process_GO_subset$GeneID, function(x) x)
head(gene2GO)

# Step 3: Load Differential Expression Data
# Read the differential expression data from a CSV file
deg_data_gene_info <- read.csv("deg_data_tximeta_gene_info.csv")

# Preview the first few rows of the dataframe
head(deg_data_gene_info)

# Extract the relevant columns: GeneID and the adjusted p-value for a specific condition (adjust this as needed)
DE <- deg_data_gene_info %>%
  dplyr::select(GeneID, X94197A1_9_2_2_2_5_padj)

# Preview the data
head(DE)

# Step 4: Define Gene List for topGO
# Set the significance cutoff for adjusted p-values
pcutoff <- 0.05

# Create a gene list: 1 for significant genes (adjP < cutoff), 0 otherwise
geneList <- ifelse(DE$X94197A1_9_2_2_2_5_padj < pcutoff, 1, 0)

# Ensure the gene names in geneList match those in GO terms
names(geneList) <- DE$GeneID
head(geneList)

# Remove any NAs from the gene list
geneList <- na.omit(geneList)

# Step 5: Set up the topGOdata object
# Create the topGOdata object for Biological Process (BP) ontology
GOdata <- new("topGOdata",
              ontology = "BP",
              allGenes = geneList,
              geneSelectionFun = function(x) (x == 1),  # Select genes where geneList == 1
              annot = annFUN.gene2GO, 
              gene2GO = gene2GO)

# Step 6: Run GO Enrichment Tests
# Use the "elim" algorithm with Fisher's Exact Test to reduce bias towards general terms
resultFisher_elim <- runTest(GOdata, algorithm = "elim", statistic = "fisher")

# Generate a table of results with all GO terms
tabFisher <- GenTable(GOdata, Fisher = resultFisher_elim, topNodes = length(resultFisher@score), numChar = 120)
head(tabFisher)

# Step 7: Visualize Top GO Terms
# Select top 20 enriched GO terms based on Fisher's Exact Test results
goEnrichment <- GenTable(GOdata, Fisher = resultFisher_elim, orderBy = "Fisher", topNodes = 20, numChar = 50)

# Filter for significant GO terms (Fisher p < 0.05)
goEnrichment$Fisher <- as.numeric(goEnrichment$Fisher)
goEnrichment <- goEnrichment[goEnrichment$Fisher < 0.05,]
goEnrichment <- goEnrichment[, c("GO.ID", "Term", "Fisher")]

# Step 8: Plot the Enriched GO Terms
# Prepare data for plotting the top 20 terms
ntop <- 20
ggdata <- goEnrichment[1:ntop,]
ggdata$Term <- factor(ggdata$Term, levels = rev(ggdata$Term))  # Set order for plotting

# Create a dot plot of the enrichment scores (-log10 of Fisher p-values)
ggplot(ggdata, aes(x = Term, y = -log10(Fisher), size = -log10(Fisher), fill = -log10(Fisher))) +
  expand_limits(y = 1) +
  geom_point(shape = 21) +
  scale_size(range = c(2.5, 12.5)) +
  scale_fill_continuous(low = 'royalblue', high = 'red4') +
  xlab("Biological Process") + ylab('Enrichment Score') +
  labs(
    title = 'GO Analysis',
    subtitle = 'Top 20 terms ordered by Fisher Exact p-value',
    caption = 'Cut-off lines at p = 0.05, 0.01, 0.001'
  ) +
  geom_hline(yintercept = c(-log10(0.05), -log10(0.01), -log10(0.001)),
             linetype = c("dotted", "longdash", "solid"),
             colour = c("black", "black", "black"),
             size = c(0.5, 1.5, 3)) +
  theme_bw(base_size = 24) +
  theme(
    legend.position = 'right',
    legend.background = element_rect(),
    plot.title = element_text(size = 16, face = 'bold'),
    plot.subtitle = element_text(size = 14, face = 'bold'),
    plot.caption = element_text(size = 12, face = 'bold'),
    axis.text.x = element_text(size = 12, face = 'bold'),
    axis.text.y = element_text(size = 12, face = 'bold'),
    axis.title = element_text(size = 12, face = 'bold'),
    axis.line = element_line(colour = 'black'),
    legend.key = element_blank(),
    legend.text = element_text(size = 14, face = "bold")
  ) +
  coord_flip()

# Save the plot as a PDF
ggplot2::ggsave("BP_GOTerms_Fisher_GS7.pdf", height = 8.5, width = 12)

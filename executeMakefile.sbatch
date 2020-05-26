#!/bin/bash
#
# see http://core.sam.pitt.edu/node/5678
#SBATCH -N 1
#SBATCH -t 0-02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mail-type=END
#SBATCH --mail-user=amf198@pitt.edu
#SBATCH --mem=128g
#SBATCH --job-name=AMF_4tU_SeqAlignment

## Loading modules for execution of all makefile rules 
# module load gcc/6.3.0
module load java/1.8.0_181-oracle
# module load samtools/1.5
module load deeptools/3.3.0
module load picard/2.18.12
module load hisat2/2.1.0 
## gcc version 8.2.0 is incompatible with ver 6.3.0 so load these separately if needed
module load gcc/8.2.0
module load bedtools/2.27.1
module load samtools/1.9
module load parallel/2017-05-22
module load edirect/10.6
module load sra-toolkit/2.9.2
module load bamtools/2.5.1
module load subread/1.6.2

# # list the make commands to take you through all steps of the pipeline
# # be careful because reruning sampleIDs will overwrite existing sampleID documents in the project directory 
# # rerun sampleIDs any time you want changes to the contents of the fastqFolder or bigwig comparioson folders to be reflected in the analysis 

# make sampleIDs
# # make unzip_fastq
# make alignment
# make zip_fastq
# make normalizedBigwig

# # these scripts will often require further specification to get perfectly right 
# make generatePCA
# make combinedBigwig
# make log2fcBigwig
make heatmaps

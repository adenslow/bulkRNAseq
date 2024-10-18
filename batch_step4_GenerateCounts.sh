#!/bin/bash
#SBATCH --job-name=R_counts
#SBATCH --mem=15GB
#SBATCH --time=10:00:00
#SBATCH --partition=short

cd /home/adenslow/Rscripts/RNAseq_processing

module load R/4.3.1-foss-2022b

#location of job script
jobscript="/home/adenslow/scripts/Rscripts/RNAseq_processing/GenerateCounts_hg38_GENCODE_new_09222024.R"

# Name of experiment
export experiment_name="AJD_QE_09222024"

# Name of ref genome
export genome="hg38"

#rpm cutoff threshold
export RPMcutoff=3

#mapped bam files with marked duplicates
export fqDir="/home/adenslow/QE_RNAseq/bamMarkedDups/"

#manifest colnames fileRoot, group, bamFile, dir
export sampleManifest="CountsScript_SampleManifest_d15_d22.csv"

Rscript "$jobscript"


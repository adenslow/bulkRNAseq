#!/bin/bash
#SBATCH --mem-per-cpu=16GB
#SBATCH --cpus-per-task=20
#SBATCH --partition=short
#SBATCH --time=12:00:00

module load SAMtools/1.12-GCC-10.2.0
module load picard/2.20.1-Java-1.8

# Input arguments
basename="$1"
input_bam="$basename""_Aligned.out.bam"
output_sorted_bam="$basename""_sorted.bam"
output_marked_duplicates_bam="$basename""_marked_duplicates.bam"

# sort bam files
samtools sort -@ 15 -o "$output_sorted_bam" "$input_bam"

# Mark duplicates using Picard
java -jar $EBROOTPICARD/picard.jar MarkDuplicates \
    INPUT="$output_sorted_bam" \
    OUTPUT="$output_marked_duplicates_bam" \
    METRICS_FILE="$basename""_metrics.txt" \
    REMOVE_DUPLICATES=false \

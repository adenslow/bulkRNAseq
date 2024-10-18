#!/bin/bash
#SBATCH --partition=short
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=16834

module load STAR/2.7.3a-GCC-6.4.0-2.28 
module load SAMtools/1.12-GCC-10.2.0
module load picard/2.20.1-Java-1.8


# Check if a command-line argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <unique_base_name>"
    exit 1
fi

# Assign the first command-line argument to a variable
key=$1
read1List=$2
read2List=$3

# Set the output directory
output_dir="./mapped/"
# Check if the output directory exists, create it if not
[ -d "$output_dir" ] || mkdir -p "$output_dir"

# Align with STAR using the lists
echo "Aligning with files:"
echo "R1:" "$read1List"
echo "R2:" "$read2List"

#path to reference genome
genomeDir="/hg38_GENCODE_ref_genome"
outFileNamePrefix="./STARaligned/${key}_"

# Run STAR
STAR --runMode alignReads \
    --quantMode GeneCounts \
    --outSAMtype BAM Unsorted \
    --genomeDir "$genomeDir" \
    --readFilesCommand zcat \
    --readFilesIn "$read1List" "$read2List" \
    --runThreadN 8 \
    --outFileNamePrefix "$outFileNamePrefix" \
    --outSAMunmapped Within KeepPairs \
    --outFilterType BySJout \
    --alignSJoverhangMin 8 \
    --alignSJDBoverhangMin 1 \
    --alignIntronMin 20 \
    --outFilterMismatchNoverReadLmax 0.04 \
    --alignIntronMax 1000000 \
    --outSAMmultNmax 1

input_bam="${outFileNamePrefix}Aligned.out.bam"
output_sorted_bam="${outFileNamePrefix}sorted.bam"

samtools sort -@ 15 -o "$output_sorted_bam" "$input_bam"

output_marked_duplicates_bam="${outFileNamePrefix}marked_duplicates.bam"

# Mark duplicates using Picard
java -jar $EBROOTPICARD/picard.jar MarkDuplicates \
    INPUT="$output_sorted_bam" \
    OUTPUT="$output_marked_duplicates_bam" \
    METRICS_FILE="${key}_metrics.txt" \
    REMOVE_DUPLICATES=false \

echo "Aligned, sorted, and marked duplicates is complete!"

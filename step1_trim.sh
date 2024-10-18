#!/bin/bash
#SBATCH --partition=express
#SBATCH --time=02:00:00
#SBATCH --mem-per-cpu=10GB
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10

module load Trim_Galore/0.6.7-GCCcore-10.3.0

# Check if a command-line argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <unique_base_name>"
    exit 1
fi

# Assign the first command-line argument to a variable
key=$1
read1=$2
read2=$3

# Set the output directory
output_dir="./trimmed_fastq/"
fastqc_output_dir="./post_trim_fastqc/"

# Check if the output directory exists, create it if not
[ -d "$output_dir" ] || mkdir -p "$output_dir"
[ -d "$fastqc_output_dir" ] || mkdir -p "$fastqc_output_dir"

# Run trim_galore with a reduced number of cores
echo "Running trim_galore for $key"

trim_galore --paired \
    --nextera \
    --phred33 \
    -o "$output_dir" \
    -j 8 \
    --fastqc_args "-o $fastqc_output_dir" \
    "${read1}" "${read2}"

# Additional commands or processing steps if needed
echo "Trimming for $key completed successfully."

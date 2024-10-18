#!/bin/bash
#SBATCH --partition=express
#SBATCH --time=00:20:00
#SBATCH --job-name=batch_STARmapping


dir=""
csv_file="${dir}/SampleManifest.csv"
job="${dir}/STAR_mapping.sh"
outputLogs="${dir}/logs/"

# Declare associative arrays to hold file paths
declare -A keys

# Initialize associative arrays for read 1 and read 2 files
declare -A read1_files
declare -A read2_files

# Loop through each line in the CSV file
while IFS=, read -r sample fastq_1 fastq_2 replicate individual dir fastq_1_trimmed fastq_2_trimmed trimmed_dir; do
    # Remove any carriage returns or extra spaces
    sample_name=$(echo "$sample" | tr -d '\r' | xargs)
    replicate_number=$(echo "$replicate" | tr -d '\r' | xargs)
    individual=$(echo "$individual" | tr -d '\r'| xargs)
    dir=$(echo "$trimmed_dir" | tr -d '\r' | xargs)
    # Create a unique key for each sample and replicate number
    key="${sample_name}_${replicate_number}"
    echo "$key"
    # Get the full path for file1 and file2
    full_file1="${dir}${fastq_1_trimmed}"
    echo "$full_file1"
    full_file2="${dir}${fastq_2_trimmed}"
    echo "$full_file2"
    # Append file1 and file2 (with full paths) to the appropriate arrays
    if [ -z "${read1_files[$key]}" ]; then
        read1_files["$key"]="$full_file1"
        read2_files["$key"]="$full_file2"
    else
        read1_files["$key"]="${read1_files[$key]},$full_file1"
        read2_files["$key"]="${read2_files[$key]},$full_file2"
    fi
done < <(tail -n +2 "$csv_file")  # Skip the header line

# Print grouped files for each key (sample + replicate)
for key in "${!read1_files[@]}"; do
    echo "Sample: $key"

    echo "Read 1 files: ${read1_files[$key]}"
    echo "Read 2 files: ${read2_files[$key]}"
    echo "------------------------"

    sbatch --job-name="align_${key}" \
           --output="${outputLogs}${key}_align.out" \
           --error="${outputLogs}${key}_align.err" \
           "$job" "$key" "${read1_files[$key]}" "${read2_files[$key]}"
done

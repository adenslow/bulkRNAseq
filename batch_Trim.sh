#!/bin/bash
#SBATCH --partition=express
#SBATCH --time=00:20:00
#SBATCH --job-name=batch_trim

# Name of directory containing sample manifest & trim job script 
dir=""

# Name of sample manifest (csv)
# Sample manifest should include:
# sample name, file1 name, file2 name, replicate number, individual, working directory name
csv_file="${dir}/SampleManifest.csv"

# name of trim job script
job="${dir}/trim.sh"


# Declare associative arrays to hold file paths
declare -A keys

# Initialize associative arrays for read 1 and read 2 files
declare -A read1_files
declare -A read2_files

# Loop through each line in the CSV file
while IFS=, read -r sample_name file1 file2 replicate_number individual dir; do
    # Remove any carriage returns or extra spaces
    sample_name=$(echo "$sample_name" | tr -d '\r' | xargs)
    replicate_number=$(echo "$replicate_number" | tr -d '\r' | xargs)
    individual=$(echo "$individual" | tr -d '\r'| xargs)
    dir=$(echo "$dir" | tr -d '\r' | xargs)
    # Create a unique key for each sample and replicate number
    key="${sample_name}_${replicate_number}_${individual}"
    # Get the full path for file1 and file2
    full_file1="${dir}${file1}"
    full_file2="${dir}${file2}"

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

    sbatch --job-name="trim_${key}" \
           --output="${key}_trim.out" \
           --error="${key}_trim.err" \
           "$job" "$key" "${read1_files[$key]}" "${read2_files[$key]}"
done












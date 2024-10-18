#!/bin/bash
#SBATCH --job-name=batch_markdups
#SBATCH --partition=express
#SBATCH --time=00:10:00

# path to aligned bam files
bam_path="/path/to/Aligned"
 
cd "$bam_path"

module load SAMtools/1.12-GCC-10.2.0
module load picard/2.20.1-Java-1.8

# path to job script
job_script="path/to/sort_and_mark_duplicates.sh"

# Read input base names from a list
shopt -s nullglob

# identify all bam files
bam=(*.bam)
base_names=()

# get the basename of each bam file
for file in "${bam[@]}"; 
do
    echo "File Identified:" "$file"
    base_name=$(echo "$file" | sed 's/\_A.*//')
    base_names+=("$base_name")
done

# Create an array of unique base names
unique_basenames=($(echo "${base_names[@]}" | tr ' ' '\n' | sort -u))

echo "Identified "${#unique_basenames[@]}" unique filenames"

# Print the unique base names
for unique_basename in "${unique_basenames[@]}"; do
    echo "Unique Base Name:" "$unique_basename"
    #if [[ " ${skip[@]} " =~ "$unique_basename" ]]; then
    #    echo "Skipping $unique_basename"
    #else
        # Perform commands on the file here
        echo "Processing $unique_basename"
        # Loop through each unique base name and submit a SLURM job
        sbatch "$job_script" "$unique_basename"
    #fi
done

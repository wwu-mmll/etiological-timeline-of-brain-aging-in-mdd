#!/bin/bash

# --- Defaults ---
CSV_FILE=""
BASE_RESULT_DIR="./output"
IMAGE_NAME="brainage_r:latest"

# --- Usage Function ---
usage() {
    echo "Usage: $0 -c <input_csv> [-o <output_dir>]"
    echo "  -c: Path to the input CSV file (required)"
    echo "  -o: Path to the output directory (default: ./output)"
    exit 1
}

# --- Parse Arguments ---
while getopts "c:o:h" opt; do
    case "$opt" in
        c) CSV_FILE=$OPTARG ;;
        o) BASE_RESULT_DIR=$OPTARG ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Ensure CSV file is provided
if [[ -z "$CSV_FILE" ]]; then
    echo "Error: Input CSV file is required."
    usage
fi

# Ensure CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: File '$CSV_FILE' not found."
    exit 1
fi

# Create base output directory if it doesn't exist
mkdir -p "$BASE_RESULT_DIR"

# --- Processing Logic ---
# 

# Read CSV, skipping the header. We use a while loop with IFS.
# Using 'sed' to skip header and 'tail' to ensure we don't process empty lines.
sed 1d "$CSV_FILE" | while IFS=';' read -r study subject assessment image_path; do
    # Trim whitespace/carriage returns (important if CSV was saved on Windows)
    study=$(echo "$study" | tr -d '\r' | xargs)
    subject=$(echo "$subject" | tr -d '\r' | xargs)
    assessment=$(echo "$assessment" | tr -d '\r' | xargs)
    image_path=$(echo "$image_path" | tr -d '\r' | xargs)

    # Skip empty lines
    [[ -z "$study" ]] && continue

    # Derive directory and filename from the image_path
    input_dir=$(dirname "$image_path")
    filename=$(basename "$image_path")
    
    # Define the specific subdirectory for this row
    folder_name="${study}_${assessment}_${subject}"
    output_subdir="${BASE_RESULT_DIR}/${folder_name}"

    # Check if this subject has already been processed
    if [ -d "$output_subdir" ]; then
        echo ">> Skipping $folder_name: Directory already exists."
        continue
    fi

    echo ">> Processing $filename into $folder_name..."
    
    # Create the specific output folder
    mkdir -p "$output_subdir"

    # Run Podman
    podman run --rm \
        -v "${input_dir}:/input:ro" \
        -v "${output_subdir}:/output" \
        "$IMAGE_NAME" brainageR -f "$filename"

done

echo "Done!"
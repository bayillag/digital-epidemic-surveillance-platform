#!/bin/bash

# ==============================================================================
# Script to Generate the Book Manuscript Files in a specific nested directory
# for "The Digital Epidemic".
# ==============================================================================
# This script is designed to run from the top-level project folder and will
# create files in the nested path: ./digital-epidemic-surveillance-platform/book
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# Define the specific, nested path to the book directory.
# This assumes you are running the script from the top-level project folder.
NESTED_BOOK_DIR="digital-epidemic-surveillance-platform/book"

echo "--- Populating the nested book manuscript directory: './$NESTED_BOOK_DIR' ---"

# Check if the target directory exists. If not, create it.
# The -p flag ensures all parent directories are created as needed.
mkdir -p "$NESTED_BOOK_DIR"

# Define the list of chapters as a bash array.
CHAPTERS=(
    "00-Foreword"
    "01-Introduction"
    "02-Chapter-1-Database-Schema"
    "03-Chapter-2-Backend-and-Data-Ingestion"
    "04-Chapter-3-Spatial-Analysis"
    "05-Chapter-4-Temporal-Analysis"
    "06-Chapter-5-Case-Tracing"
    "07-Chapter-6-Main-Dashboard"
    "08-Chapter-7-Vaccination-Dashboard"
    "09-Chapter-8-SERVAL-Dashboard"
    "10-Chapter-9-Report-Generation"
    "11-Chapter-10-GEE-Integration"
    "12-Chapter-11-QGIS-Integration"
    "13-Chapter-12-The-Future-of-Surveillance"
)

# Loop through the array of chapter filenames.
for chapter_file in "${CHAPTERS[@]}"; do
    # Derive a clean, human-readable title from the filename.
    CLEAN_NAME=$(echo "$chapter_file" | sed 's/^[0-9]*-//')
    TITLE=$(echo "$CLEAN_NAME" | sed 's/-/ /g' | sed 's/Chapter \([0-9]*\)/Chapter \1:/')

    # Define the full output path for the Markdown file using the nested directory variable.
    OUTPUT_FILE="${NESTED_BOOK_DIR}/${chapter_file}.md"

    # Use a 'here document' (cat << EOF) to write the content to the file.
    cat << EOF > "$OUTPUT_FILE"
# $TITLE

*(The full content for this chapter can be generated from the previous prompts.)*

*(This file was automatically generated.)*
EOF

    # Print a confirmation message for each file created.
    echo "   Created: $OUTPUT_FILE"
done

echo ""
echo "✅ All book manuscript files have been created successfully in the nested 'book/' directory."


#!/bin/bash

# ==============================================================================
# Script to Populate the Book Manuscript Files for "The Digital Epidemic"
# ==============================================================================
# This script assumes the 'book/' directory already exists at the project root.
# It will create a Markdown file for each chapter with a formatted title
# and placeholder text. It is safe to run multiple times.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Populating the 'book/' directory with manuscript files... ---"

# Check if the book directory exists. If not, inform the user.
if [ ! -d "book" ]; then
    echo "Error: 'book' directory not found. Please run this script from the project root directory."
    exit 1
fi

# Define the list of chapters as a bash array.
# The filenames are prefixed with numbers to ensure correct ordering.
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
    # 1. Remove the "00-" prefix.
    # 2. Replace all remaining hyphens with spaces.
    # 3. For chapters, replace the first space after "Chapter" with a colon.
    CLEAN_NAME=$(echo "$chapter_file" | sed 's/^[0-9]*-//')
    TITLE=$(echo "$CLEAN_NAME" | sed 's/-/ /g' | sed 's/Chapter \([0-9]*\)/Chapter \1:/')

    # Define the full output path for the Markdown file.
    OUTPUT_FILE="book/${chapter_file}.md"

    # Use a 'here document' (cat << EOF) to write the content to the file.
    # This is a clean way to handle multi-line strings in bash.
    cat << EOF > "$OUTPUT_FILE"
# $TITLE

*(The full content for this chapter can be generated from the previous prompts.)*

*(This file was automatically generated.)*
EOF

    # Print a confirmation message for each file created.
    echo "   Created: $OUTPUT_FILE"
done

echo ""
echo "✅ All book manuscript files have been created successfully in the 'book/' directory."
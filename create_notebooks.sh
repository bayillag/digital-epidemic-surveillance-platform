
#!/bin/bash

# ==============================================================================
# Script to Generate the Jupyter Notebook Files in a specific nested directory
# for "The Digital Epidemic".
# ==============================================================================
# This script is designed to run from the top-level project folder and will
# create files in the nested path: 
# ./digital-epidemic-surveillance-platform/notebooks
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# Define the specific, nested path to the notebooks directory.
# This assumes you are running the script from the top-level project folder.
NESTED_NOTEBOOKS_DIR="digital-epidemic-surveillance-platform/notebooks"

echo "--- Populating the nested notebooks directory: './$NESTED_NOTEBOOKS_DIR' ---"

# Check if the target directory exists. If not, create it.
# The -p flag ensures all parent directories are created as needed.
mkdir -p "$NESTED_NOTEBOOKS_DIR"

# Define the list of notebook filenames (without extension).
NOTEBOOKS=(
    "01-Main-Dashboard"
    "02-Vaccination-Campaign-Dashboard"
    "03-Outbreak-Investigation-Dashboard"
    "04-Epi-Curve-and-EDR-Dashboard"
    "05-GEE-Environmental-Dashboards"
    "06-Master-Report-Generator"
)

# A minimal, valid JSON structure for an empty Jupyter Notebook.
# Using a 'here document' with single quotes to preserve the literal string.
NOTEBOOK_TEMPLATE='{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# {TITLE}\n\n",
    "This notebook contains the complete Python code for the corresponding dashboard or analysis module.\n\n",
    "**Prerequisites:**\n",
    "1. Ensure your `.env` file is configured with Supabase credentials.\n",
    "2. Ensure all required libraries from `requirements.txt` are installed in your virtual environment."
   ]
  }
 ],
 "metadata": {},
 "nbformat": 4,
 "nbformat_minor": 2
}'

# Loop through the array of notebook filenames.
for nb_file in "${NOTEBOOKS[@]}"; do
    # Derive a clean, human-readable title from the filename.
    CLEAN_NAME=$(echo "$nb_file" | sed 's/^[0-9]*-//')
    TITLE=$(echo "$CLEAN_NAME" | sed 's/-/ /g')

    # Substitute the placeholder {TITLE} in the template with the actual title.
    # We use double quotes here to allow for the $TITLE variable expansion.
    CONTENT=$(echo "$NOTEBOOK_TEMPLATE" | sed "s/{TITLE}/$TITLE/")

    # Define the full output path for the .ipynb file.
    OUTPUT_FILE="${NESTED_NOTEBOOKS_DIR}/${nb_file}.ipynb"

    # Write the JSON content to the file.
    echo "$CONTENT" > "$OUTPUT_FILE"

    # Print a confirmation message for each file created.
    echo "   Created: $OUTPUT_FILE"
done

echo ""
echo "✅ All Jupyter Notebook files have been created successfully in the nested 'notebooks/' directory."
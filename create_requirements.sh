#!/bin/bash

# ==============================================================================
# Script to Generate the requirements.txt file in a specific nested directory
# for "The Digital Epidemic".
# ==============================================================================
# This script is designed to run from the top-level project folder and will
# create the requirements.txt file in the nested path: 
# ./digital-epidemic-surveillance-platform/
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# Define the specific, nested path to the project root directory.
NESTED_PROJECT_DIR="digital-epidemic-surveillance-platform"

echo "--- Creating requirements.txt in: './$NESTED_PROJECT_DIR/' ---"

# Check if the target directory exists. If not, inform the user and exit.
if [ ! -d "$NESTED_PROJECT_DIR" ]; then
    echo "Error: Nested project directory './$NESTED_PROJECT_DIR/' not found."
    echo "Please run this script from the top-level project folder."
    exit 1
fi

# Define the full output path for the requirements.txt file.
OUTPUT_FILE="${NESTED_PROJECT_DIR}/requirements.txt"

# --- Write the list of required Python packages to the file ---
# Using a 'here document' (cat << 'EOF') for the multi-line content.
# The list is alphabetized for clarity.
echo "   Creating: $OUTPUT_FILE"
cat << 'EOF' > "$OUTPUT_FILE"
# ==============================================================================
# Python package requirements for the
# Digital Epidemic Surveillance Platform
# ==============================================================================
# Install these packages using: pip install -r requirements.txt
# It is highly recommended to use a virtual environment.
# ==============================================================================

# Core Data Handling and Analysis
pandas
geopandas
matplotlib
shapely # A core dependency for geopandas

# Database and Backend
supabase
python-dotenv

# Geospatial and Mapping
folium
earthengine-api
geemap

# Spatial Statistics (PySAL Family)
esda
libpysal
splot

# Interactive Dashboards
ipywidgets
tqdm # For progress bars

# Report Generation
python-docx # For .docx files
selenium # For capturing map images
webdriver-manager # For managing selenium drivers
weasyprint # For generating .pdf files from HTML
EOF

echo ""
echo "✅ requirements.txt file has been created successfully."
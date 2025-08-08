#!/bin/bash

# ==============================================================================
# Script to Generate the .gitignore file in a specific nested directory
# for "The Digital Epidemic".
# ==============================================================================
# This script is designed to run from the top-level project folder and will
# create the .gitignore file in the nested path: 
# ./digital-epidemic-surveillance-platform/
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# Define the specific, nested path to the project root directory.
NESTED_PROJECT_DIR="digital-epidemic-surveillance-platform"

echo "--- Creating .gitignore in: './$NESTED_PROJECT_DIR/' ---"

# Check if the target directory exists. If not, create it to be robust.
mkdir -p "$NESTED_PROJECT_DIR"

# Define the full output path for the .gitignore file.
OUTPUT_FILE="${NESTED_PROJECT_DIR}/.gitignore"

# --- Write the content of the .gitignore file ---
# Using a 'here document' (cat << 'EOF') for the multi-line content.
echo "   Creating: $OUTPUT_FILE"
cat << 'EOF' > "$OUTPUT_FILE"
# ==============================================================================
# Git Ignore file for the Digital Epidemic Surveillance Platform
# ==============================================================================
# This file tells Git which files and folders to intentionally ignore.
# It's crucial for keeping the repository clean and secure.

# --- Environment Variables ---
# Never commit credentials or secrets!
.env
.env*
!.env.example

# --- Python ---
# Virtual environments
venv/
env/
.venv/

# Compiled Python files and caches
__pycache__/
*.pyc
*.pyo
*.pyd
*.egg-info/
dist/
build/

# --- Jupyter Notebook ---
# Checkpoints are auto-saved backups and clutter the repository.
.ipynb_checkpoints/

# --- Generated Reports ---
# These are build artifacts, not source code, and should not be versioned.
*.html
*.pdf
*.docx

# --- Temporary Files ---
# Images and logs created by the reporting engine.
*.png
*.log

# --- IDE / Editor Configuration ---
# User-specific settings that don't belong in a shared repository.
.idea/
.vscode/
*.swp
*~

# --- OS-specific files ---
.DS_Store
Thumbs.db
EOF

echo ""
echo "✅ .gitignore file has been created successfully."
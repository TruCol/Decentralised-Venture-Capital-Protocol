#!/bin/bash

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
  echo "Error: pandoc is not installed. Please install it using your package manager."
  exit 1
fi

# Get the input and output filenames from command line arguments
input_file="$1"
output_file="${input_file%.*}.md"  # Remove extension and add .md

# Check if input file exists
if [[ ! -f "$input_file" ]]; then
  echo "Error: Input file '$input_file' does not exist."
  exit 1
fi

# Convert the HTML file to Markdown
pandoc -f html -t markdown -o "$output_file" "$input_file"

# Success message
echo "Converted '$input_file' to '$output_file'"

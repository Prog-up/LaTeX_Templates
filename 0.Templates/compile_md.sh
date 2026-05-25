#!/bin/bash

# Check for argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <markdown_file>"
    echo "Example: $0 rapport-md.md"
    exit 1
fi

INPUT_FILE="$1"
BASENAME="${INPUT_FILE%.*}"
OUTPUT_FILE="${BASENAME}.pdf"
TEX_FILE="${BASENAME}.tex"
TEMPLATE_FILE="template.tex"
# Note: the bibliography file is hardcoded to references.bib inside the template.tex file

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE not found."
    exit 1
fi

echo "Compiling $INPUT_FILE to $OUTPUT_FILE..."

# 1. Generate LaTeX source from Markdown using Pandoc
pandoc "$INPUT_FILE" \
    --template="$TEMPLATE_FILE" \
    --listings \
    --extract-media . \
    -t latex \
    -o "$TEX_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Markdown to LaTeX conversion failed."
    exit 1
fi

# 2. Compile LaTeX to PDF with glossary and bibliography support
# First pass
pdflatex -interaction=nonstopmode "$TEX_FILE" > /dev/null

# Process Glossary
if [ -f "${BASENAME}.glo" ]; then
    makeglossaries "$BASENAME" > /dev/null
fi

# Process Bibliography
if [ -f "${BASENAME}.bcf" ]; then
    biber "$BASENAME" > /dev/null
fi

# Second and third passes to resolve references
pdflatex -interaction=nonstopmode "$TEX_FILE" > /dev/null
pdflatex -interaction=nonstopmode "$TEX_FILE" > /dev/null

# Check final result
if [ -f "$OUTPUT_FILE" ]; then
    echo "Success: $OUTPUT_FILE generated."
    # Optional: cleanup auxiliary files
    rm -f "${BASENAME}.aux" "${BASENAME}.log" "${BASENAME}.out" "${BASENAME}.toc" "${BASENAME}.tex" "${BASENAME}.bcf" "${BASENAME}.run.xml" "${BASENAME}.glo" "${BASENAME}.ist" "${BASENAME}.gls" "${BASENAME}.glg" "${BASENAME}.blg" "${BASENAME}.bbl"
else
    echo "Error: PDF generation failed."
    exit 1
fi

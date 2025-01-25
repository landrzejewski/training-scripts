#!/bin/bash

SRC_DIR="src"
TARGET_DIR="target"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Source directory '$SRC_DIR' does not exist."
  exit 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target directory '$TARGET_DIR' does not exist. Creating it..."
  mkdir -p "$TARGET_DIR"
  if [[ $? -ne 0 ]]; then
    echo "Failed to create target directory '$TARGET_DIR'."
    exit 1
  fi
fi

md_files=("$SRC_DIR"/*.md)

if [[ ! -e "${md_files[0]}" ]]; then
  echo "No Markdown files found in the '$SRC_DIR' directory."
  exit 1
fi

for mdfile in "$SRC_DIR"/*.md; do
  FILE_BASENAME=$(basename "$mdfile" .md)

  echo "Processing '$mdfile'..."

#  pandoc \
#    -f markdown \
#    -t html5 \
#    -o "${TARGET_DIR}/${FILE_BASENAME}.html" \
#    "$mdfile" \
#    -c "../styles.css" \
#    --standalone \
#    --highlight-style=highlight.theme \
#    --toc \
#    --toc-depth=2 \
#    --number-sections
#
#  if [[ $? -ne 0 ]]; then
#    echo "Error converting '$mdfile' to HTML."
#    continue
#  fi

  pandoc "$mdfile" \
         -o "${TARGET_DIR}/${FILE_BASENAME}.pdf" \
         --toc \
         --toc-depth=1 \
         --number-sections \
         --top-level-division=chapter \
         --highlight-style=highlight.theme \
         --pdf-engine=lualatex \
         --template=template.tex

  if [[ $? -ne 0 ]]; then
    echo "Error converting '$mdfile' to PDF."
    continue
  fi

  echo "Successfully processed '$mdfile'."
done

echo "All files have been processed."

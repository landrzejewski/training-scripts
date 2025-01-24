DOCUMENT_TITLE="Rust programming for embedded systems"
FILE_BASENAME="RUST-EMBEDDED"

pandoc \
  -f markdown \
  -t html5 \
  -o "${FILE_BASENAME}.html" \
  "${FILE_BASENAME}.md" \
  -c styles.css \
  --standalone \
  --highlight-style tango \
  --metadata title="${DOCUMENT_TITLE:-Untitled Document}" \
  --toc \
  --toc-depth=2 \
  --number-sections

pandoc -N --variable "geometry=margin=1.2in"  "${FILE_BASENAME}.md" \
  -o "${FILE_BASENAME}.pdf" \
  --metadata title="${DOCUMENT_TITLE:-Untitled Document}" \
  --toc \
  --toc-depth=1 \
  --number-sections \
  --highlight-style tango \
  --pdf-engine=lualatex
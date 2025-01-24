DOCUMENT_TITLE="Rust Programming for Embedded Systems"
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


#pandoc -N --variable "geometry=margin=1.2in" --variable mainfont="Palatino" --variable sansfont="Helvetica" \
#  --variable monofont="Menlo" --variable fontsize=12pt --variable version=2.0 RUST-EMBEDDED.md \
#  --metadata title="Rust Programming for Embedded Systems" --toc --toc-depth=2 --number-sections \
#  --pdf-engine=lualatex -o output.pdf
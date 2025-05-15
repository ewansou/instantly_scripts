#!/bin/bash
# watch_autocrop.sh
# Monitors ~/Desktop/Source for new JPEG/JPG files on Windows via Git Bash
# by polling with a while loop and automatically cropping white borders,
# then removes default pixels from the top, left, and right sides,
# saving to ~/Desktop/Moved.

# === CONFIGURABLE PATHS ===
SRC_DIR="$HOME/Desktop/Source"
DEST_DIR="$HOME/Desktop/Moved"
FUZZ="50%"               # Tolerance for near-white pixels

# === DEFAULT CROP VALUES ===
DEFAULT_TOP="18"         # Pixels to remove from the top edge
DEFAULT_LEFT="20"        # Pixels to remove from the left side
DEFAULT_RIGHT="20"       # Pixels to remove from the right side
POLL_INTERVAL="3"        # Seconds between directory scans

# Ensure directories exist
mkdir -p "$SRC_DIR" "$DEST_DIR"

echo "Polling $SRC_DIR every $POLL_INTERVAL seconds for new JPEGs..."

# Function to process a single image
process_image() {
  local input_file="$1"
  local basename="$(basename "$input_file")"
  local output_file="$DEST_DIR/$basename"

  echo "🔧 Processing '$basename'..."
  magick "$input_file" \
    -auto-orient \
    -background white -alpha remove -alpha off \
    -fuzz "$FUZZ" \
    -trim +repage \
    -gravity North -chop 0x${DEFAULT_TOP} \
    -gravity West  -chop ${DEFAULT_LEFT}x0 \
    -gravity East  -chop ${DEFAULT_RIGHT}x0 \
    "$output_file"

  if [[ $? -eq 0 ]]; then
    echo "✔ Saved: $output_file"
  else
    echo "❌ Failed to process: $basename"
  fi
}

# Enable extended globbing for nullglob
shopt -s nullglob

# Polling loop using while-read
while true; do
  # List JPEGs and feed into while loop
  ls "$SRC_DIR"/*.{jpg,jpeg,JPG,JPEG} 2>/dev/null | while IFS= read -r input_file; do
    # Ensure it's a file
    [[ -f "$input_file" ]] || continue
    basename="$(basename "$input_file")"
    # Skip if already processed
    [[ -f "$DEST_DIR/$basename" ]] && continue
    process_image "$input_file"
  done
  sleep "$POLL_INTERVAL"
done

# Disable nullglob
shopt -u nullglob

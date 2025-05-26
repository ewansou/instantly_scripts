#!/bin/bash
# watch_autocrop.sh
# Place this script inside a folder named 'process2025'.
# It will create and monitor 'Source', 'Moved', and 'Hold' subfolders within that directory,
# auto-cropping new JPEG/JPG files as they arrive.

# === DETERMINE BASE DIRECTORY ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR"

# === CONFIGURABLE PATHS ===
SRC_DIR="$BASE_DIR/Source"
DEST_DIR="$BASE_DIR/Moved"
HOLD_DIR="$BASE_DIR/Hold"
FUZZ="50%"               # Tolerance for near-white pixels

# === DEFAULT CROP VALUES ===
DEFAULT_TOP="18"         # Pixels to remove from the top edge
DEFAULT_LEFT="20"        # Pixels to remove from the left side
DEFAULT_RIGHT="20"       # Pixels to remove from the right side
POLL_INTERVAL="3"        # Seconds between directory scans

# === IMAGE MAGICK ARGUMENTS ===
# Define the crop and chop options in a single variable
IM_ARGS=(
  -auto-orient
  -background white -alpha remove -alpha off
  -fuzz "$FUZZ"
  -trim +repage
  -gravity North -chop 0x${DEFAULT_TOP}
  -gravity West  -chop ${DEFAULT_LEFT}x0
  -gravity East  -chop ${DEFAULT_RIGHT}x0
)

# === INITIALIZE FOLDERS ===
echo "Initializing directories in: $BASE_DIR"
mkdir -p "$SRC_DIR" "$DEST_DIR" "$HOLD_DIR"

# === STOPPER SETUP ===
echo "Press ENTER at any time to stop the watcher."
read -r _STOP_SIGNAL &
STOP_PID=$!

# === FUNCTION: PROCESS SINGLE IMAGE ===
process_image() {
  local input_file="$1"
  local filename="$(basename "$input_file")"
  local output_file="$DEST_DIR/$filename"

  echo "🔧 Processing '$filename'..."
  # Use the parameterized ImageMagick options
  magick "$input_file" "${IM_ARGS[@]}" "$output_file"

  if [[ $? -eq 0 ]]; then
    echo "✔ Saved: $output_file"
  else
    echo "❌ Failed: $filename"
  fi
}

# === WATCH LOOP (POLLING) ===
shopt -s nullglob
while kill -0 "$STOP_PID" 2>/dev/null; do
  for input_file in "$SRC_DIR"/*.{jpg,jpeg,JPG,JPEG}; do
    [[ -f "$input_file" ]] || continue
    filename="$(basename "$input_file")"
    [[ -f "$DEST_DIR/$filename" ]] && continue
    process_image "$input_file"
  done
  sleep "$POLL_INTERVAL"
done
shopt -u nullglob

# === CLEAN UP AND EXIT ===
kill "$STOP_PID" 2>/dev/null
echo "Watcher stopped by user."
read -p "Press ENTER to exit..."

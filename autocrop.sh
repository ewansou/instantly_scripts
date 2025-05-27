#!/bin/bash
# watch_autocrop.sh
# Place this script inside a folder named 'process2025'.
# It creates and monitors 'Source', 'Moved', and 'Hold' subfolders,
# crops new JPEG/JPG files as they arrive, then moves originals to 'Hold'.
# Type 'exit' at the prompt to end.

# === BASE DIRECTORY ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR"

# === PATHS & SETTINGS ===
SRC_DIR="$BASE_DIR/tempDisplay"
DEST_DIR="$BASE_DIR/Output"
MOVED_DIR="$BASE_DIR/Moved"
WIDTH=600            
HEIGHT=900
X=20
Y=921
POLL_INTERVAL=3            

# === INIT ===
echo "Initializing under: $BASE_DIR"
mkdir -p "$SRC_DIR" "$DEST_DIR" "$MOVED_DIR"

# === PROCESS IMAGE ===
process_image() {
  local input_fileWfullfilepath="$1"
  local input_filename="$(basename "$input_fileWfullfilepath")"
  local output_file="$DEST_DIR/$input_filename"


#for error checking----
#echo "*********"
#echo "${input_fileWfullfilepath}"
#echo "*********"
#echo "${input_filename}"
#echo "*********"
#echo "${output_file}"
#echo "*********"

  echo "🔧 Processing $in"
  magick "${input_fileWfullfilepath}" -crop ${WIDTH}x${HEIGHT}+${X}+${Y} "${output_file}"
  if [[ $? -eq 0 ]]; then
    #echo "✔ Saved: $out"
    mv "${input_fileWfullfilepath}" "$MOVED_DIR"
    #echo "🔀 Moved original to Hold"
  else
    echo "❌ Failed: $base"
  fi
}

# === WATCH LOOP ===
shopt -s nullglob
echo "Watching $SRC_DIR (poll every $POLL_INTERVAL s)"
while true; do
  for f in "$SRC_DIR"/*.{jpg,jpeg,JPG,JPEG}; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f")"
    [[ -f "$DEST_DIR/$base" ]] && continue
    process_image "$f"
  done

  printf "\nType 'exit' to quit; otherwise the watcher will continue after %s seconds...\n" "$POLL_INTERVAL"
  read -t "$POLL_INTERVAL" cmd
  if [[ "$cmd" == "exit" ]]; then
    echo "Exiting watcher..."
    break
  fi
done
shopt -u nullglob

echo "Cleanup done. Goodbye."
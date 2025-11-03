#!/usr/bin/env bash

# Reusable file watcher for specific extensions (e.g., jpg,jpeg)  #MUST MAKE SURE ARGUMENTS ARE IN ORDER
watch_for_new_images() {
  local SRC_DIR="$1"
  local DEST_DIR="$2"
  local POLL_INTERVAL="$3"
  local PROCESS_FN="$4"
  local FILE_TYPES="$5" # e.g., "jpg,jpeg,JPG,JPEG"

  shopt -s nullglob
  echo "📂 Watching '$SRC_DIR' for new files with extensions: $FILE_TYPES (every $POLL_INTERVAL s)..."

  # Convert comma-separated list into array
  IFS=',' read -ra EXTENSIONS <<<"$FILE_TYPES"

  while true; do
    for ext in "${EXTENSIONS[@]}"; do
      for f in "$SRC_DIR"/*."$ext"; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        [[ -f "$DEST_DIR/$base" ]] && continue
        "$PROCESS_FN" "$f"
      done
    done

    printf "\nType 'exit' to quit; otherwise the watcher continues after %s seconds...\n" "$POLL_INTERVAL"
    read -t "$POLL_INTERVAL" cmd
    if [[ "$cmd" == "exit" ]]; then
      echo "👋 Exiting watcher..."
      break
    fi
  done

  shopt -u nullglob
  echo "🧹 Cleanup done. Returning to menu."
}

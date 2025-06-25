#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#echo "$SCRIPT_DIR"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PARENT_DIR/watcher.sh"


#function below
crop_image() {
  # === BASE DIRECTORY ===
  source "$SCRIPT_DIR/config-01-Crop.txt"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # === PATHS & SETTINGS ===
    BASE_DIR="$SCRIPT_DIR"
    SRC_DIR="$BASE_DIR/tempDisplay"
    DEST_DIR="$BASE_DIR/Output"
    MOVED_DIR="$BASE_DIR/Moved"
    POLL_INTERVAL=5
#show the config file settings

# === DEBUG CHECKPOINT 1: VERIFY THE PATH ===
  echo "Width: $WIDTH"
  echo "Height: $HEIGHT"
  echo "X: $X"
  echo "Y: $Y"
  echo "Command: $COMMAND"
  echo "Poll Interval: $POLL_INTERVAL" 

  #watch_for_new_images "$SRC_DIR" "$DEST_DIR" "$POLL_INTERVAL" process "jpg,jpeg"
  #echo "$SRC_DIR"

    process() {
    local input_file="$1"
    local filename="$(basename "$input_file")"
    local output_file="$DEST_DIR/$filename"

    echo "🔧 Processing '$filename'..."

    local final_command=$(eval echo "$COMMAND")
    echo "🧪 Final command: $final_command"

    eval "$COMMAND"

    if [[ $? -eq 0 ]]; then
      mv "$input_file" "$MOVED_DIR"
      echo "✔ Saved: $output_file"
      echo "🔀 Moved original to $MOVED_DIR"
    else
      echo "❌ Failed to crop: $filename"
    fi
  }

  watch_for_new_images "$SRC_DIR" "$DEST_DIR" "$POLL_INTERVAL" process "jpg,jpeg,JPG,JPEG"

}

crop_image
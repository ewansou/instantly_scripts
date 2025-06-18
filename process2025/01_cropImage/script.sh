#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PARENT_DIR/watch_helper.sh"

crop_image() {

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/config.txt"

  #Display what is in the config file
  echo "Width: $WIDTH"
  echo "Height: $HEIGHT"
  echo "X: $X"
  echo "Y: $Y"
  echo "Command: $COMMAND"

  SRC_DIR="$SCRIPT_DIR/Source"
  DEST_DIR="$SCRIPT_DIR/Output"
  MOVED_DIR="$SCRIPT_DIR/Moved"

  POLL_INTERVAL=5

  echo "Initializing folders under: $SCRIPT_DIR"
  mkdir -p "$SRC_DIR" "$DEST_DIR" "$MOVED_DIR"

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
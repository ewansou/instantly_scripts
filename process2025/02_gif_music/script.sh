#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PARENT_DIR/watcher.sh"

add_music() {
  # === BASE DIRECTORY ===
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/config-02-addmusic.txt"

# === PATHS & SETTINGS ===
    BASE_DIR="$SCRIPT_DIR"
    SRC_DIR="$BASE_DIR/tempDisplay"
    INPUT_VIDEO="$BASE_DIR/tempDisplay/input.mp4"
    OUTPUT_DIR="$BASE_DIR/Output"
    MOVED_DIR="$BASE_DIR/Moved"
    MUSIC_FILE="$BASE_DIR/bg_music/background_music.mp3"
    POLL_INTERVAL=20
      # === PATHS & SETTINGS ===
#  INPUT_VIDEO="$BASE_DIR/02_gif_music/tempDisplay/input.mp4"
 # OUTPUT_DIR="$BASE_DIR/02_gif_music/Output"
  #MOVED_DIR="$BASE_DIR/02_gif_music/Moved"
  #MUSIC_FILE="$BASE_DIR/02_gif_music/bg_music/background_music.mp3"
  #Display what is in the config file


  echo "Input Video: $INPUT_VIDEO"
  echo " ======================================= ======================================="
  echo "Output Location: $OUTPUT_DIR"
  echo " ======================================= ======================================="
  echo "Original Video: $MOVED_DIR"
  echo " ======================================= ======================================="
  echo "Music Used: $MUSIC_FILE"
  echo " ======================================= ======================================="

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
      echo "❌ Failed to add music to: $filename"
    fi
  }

  watch_for_new_images "$SRC_DIR" "$DEST_DIR" "$POLL_INTERVAL" process "mp4,Mp4,MP4"
 
}

add_music
#!/usr/bin/env bash
#
# multi_tool.sh
# A single-file, menu-driven script with a reusable watch loop for any processing.

##############################
# 1) OPTIONAL GLOBAL CONFIG
##############################

CONFIG_FILE="./config.txt"
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

##############################
# 2) MENU LOGIC
##############################

show_menu() {
  cat <<EOF

---------------------------------
   Choose a tool to run:
     1) Crop images
     2) Add music to videos
     3) Another tool (placeholder)
     0) Exit
---------------------------------
EOF
  echo -n "Enter your choice [0-3]: "
}

main_menu() {
  while true; do
    show_menu
    read -r CHOICE
    case "$CHOICE" in
      1) crop_image       ;;
      2) add_music_to_video ;;
      3) another_tool     ;;
      0) echo "Goodbye!"; exit 0 ;;
      *) echo "Invalid choice; please enter 0-3." ;;
    esac
    echo
  done
}

##############################
# 3) SHARED WATCHER HELPER
##############################
#
# watch_loop <src> <dest> <moved> <interval> <pattern> <processor_fn>
#
watch_loop() {
  local SRC_DIR="$1" DEST_DIR="$2" MOVED_DIR="$3"
  local INTERVAL="$4" GLOB_PATTERN="$5" PROCESS_FN="$6"

  mkdir -p "$SRC_DIR" "$DEST_DIR" "$MOVED_DIR"
  shopt -s nullglob extglob

  echo "Watching '$SRC_DIR' for $GLOB_PATTERN (every $INTERVAL s)…"
  while true; do
    for f in "$SRC_DIR"/$GLOB_PATTERN; do
      [[ -f "$f" ]] || continue
      $PROCESS_FN "$f" && mv "$f" "$MOVED_DIR"
    done

    printf "\nType 'exit' to quit; otherwise resume in %s seconds…\n" "$INTERVAL"
    read -t "$INTERVAL" cmd
    [[ "$cmd" == "exit" ]] && break
  done

  shopt -u nullglob extglob
  echo "Watcher stopped."
}

##############################
# 4) TOOL: CROP IMAGE
##############################
##############################
# 4) TOOL: CROP IMAGE
##############################
crop_image() {
  source "01_crop_image\config-01-Crop.txt" 
  # --- 1. Load the tool-specific configuration ---
  local CONFIG_FOR_CROP="config-01-Crop.txt"
  if [[ ! -f "$CONFIG_FOR_CROP" ]]; then
    echo "❌ Error: Crop tool config not found at '$CONFIG_FOR_CROP'"
    return 1 # Exit the function
  fi
  source "$CONFIG_FOR_CROP"

  # --- 2. VALIDATE required variables ---
  if [[ -z "$SRC_DIR" || -z "$DEST_DIR" || -z "$MOVED_DIR" || -z "$POLL_INTERVAL" || -z "$IMAGICK_ARGS" ]]; then
    echo "❌ Error: A required variable (e.g., SRC_DIR, IMAGICK_ARGS) is not set in '$CONFIG_FOR_CROP'."
    return 1
  fi

  # --- 3. Set up paths relative to the script's location ---
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local FULL_SRC_DIR="$SCRIPT_DIR/$SRC_DIR"
  local FULL_DEST_DIR="$SCRIPT_DIR/$DEST_DIR"
  local FULL_MOVED_DIR="$SCRIPT_DIR/$MOVED_DIR"

  # --- 4. Define the processor function ---
  # This function now uses the generic IMAGICK_ARGS variable
  process_image() {
    local in="$1"
    local base
    base="$(basename "$in")"
    local out="$FULL_DEST_DIR/$base"

    # THIS IS THE KEY CHANGE:
    # Safely convert the argument string from the config file into a Bash array.
    # This correctly handles spaces and other special characters.
    local -a args_array
    read -r -a args_array <<< "$IMAGICK_ARGS"

    echo "🔧 Processing $base with options: ${IMAGICK_ARGS}"

    # Execute the command, safely expanding the array of arguments.
    # The script controls the COMMAND ('magick'), the config controls the OPTIONS.
    magick "$in" "${args_array[@]}" "$out"
  }

  # --- 5. Call the generic watcher with our specific settings ---
  watch_loop \
    "$FULL_SRC_DIR" \
    "$FULL_DEST_DIR" \
    "$FULL_MOVED_DIR" \
    "$POLL_INTERVAL" \
    "*.{jpg,jpeg,JPG,JPEG,png,PNG}" \
    "process_image"
}

##############################
# 5) TOOL: ADD MUSIC TO VIDEO
##############################
add_music_to_video() {
  source "config-02-addmusic.txt"  # defines SRC_DIR, DEST_DIR, MOVED_DIR, MUSIC_FILE, POLL_INTERVAL

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  SRC_DIR="$SCRIPT_DIR/$SRC_DIR"
  DEST_DIR="$SCRIPT_DIR/$DEST_DIR"
  MOVED_DIR="$SCRIPT_DIR/$MOVED_DIR"

  process_video() {
    local in="$1"
    local base="$(basename "$in")"
    local out="$DEST_DIR/with_music_$base"
    echo "🎵 Merging $base + $(basename "$MUSIC_FILE")"
    ffmpeg -y -i "$in" -i "$MUSIC_FILE" \
      -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 \
      "$out" &>/dev/null
  }

  watch_loop \
    "$SRC_DIR" \
    "$DEST_DIR" \
    "$MOVED_DIR" \
    "$POLL_INTERVAL" \
    "*.{mp4,mov,mkv,MP4,MOV,MKV}" \
    process_video
}

##############################
# 6) PLACEHOLDER TOOL
##############################
another_tool() {
  echo ">> Running placeholder tool…"
  sleep 1
  echo "   (complete)"
}

##############################
# 7) START SCRIPT
##############################
main_menu

#!/usr/bin/env bash
#
# multi_tool.sh
# A single‐file, menu‐driven script.  The “menu loop” and dispatch logic appear
# first (inside main_menu), then the tool functions are defined below, and finally
# we call main_menu to start everything.

##############################
# 1) OPTIONAL CONFIGURATION
##############################

# If you need to source a config.txt for tools like add_music_to_video,
# keep these lines.  (If config.txt doesn’t exist, we simply skip it.)
CONFIG_FILE="./config.txt"
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

##############################
# 2) MENU LOGIC (ABOVE EVERYTHING)
##############################

# 2.1) show_menu: prints the options to screen
show_menu() {
  echo "---------------------------------"
  echo "   Choose a tool to run:"
  echo "     1) Crop image "
  echo "     2) Add music to video"
  echo "     3) Another tool (placeholder)"
  echo "     0) Exit"
  echo "---------------------------------"
  echo -n "Enter your choice [0-3]: "
}

# 2.2) main_menu: the loop that reads your choice and dispatches to the correct function
main_menu() {
  while true; do
    show_menu
    read -r CHOICE

    case "$CHOICE" in
      1)
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        bash "$SCRIPT_DIR/01_crop_image/script.sh"
        ;;
      2)
        add_music_to_video
        ;;
      3)
        another_tool
        ;;
      0)
        echo "Exiting. Goodbye!"
        exit 0
        ;;
      *)
        echo "Invalid choice. Please enter 0, 1, 2, or 3."
        ;;
    esac

    echo    # blank line for readability before showing menu again
  done
}

##############################
# 3) FUNCTION DEFINITIONS (ALL TOOLS BELOW)
##############################

# 3.1) crop_image: in‐script watcher that crops any new JPG/JPEG in tempDisplay/
#               and moves originals to Moved/.  Crops to WIDTHxHEIGHT at +X+Y.
#crop_image() {
  # === BASE DIRECTORY ===
#  source "config-01-Crop.txt"
#  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#  BASE_DIR="$SCRIPT_DIR"

  # === PATHS & SETTINGS ===
#  SRC_DIR="$BASE_DIR/01_crop_image/tempDisplay"
#  DEST_DIR="$BASE_DIR/01_crop_image/Output"
#  MOVED_DIR="$BASE_DIR/01_crop_image/Moved"

  # Hard‐coded crop parameters (i want to try if can set default.)
  #WIDTH=600
  #HEIGHT=900
  #X=20
  #Y=921

# Checks every 5 seconds
  POLL_INTERVAL=5

  # === INIT: create folders if they don’t exist ===
  echo "Initializing image-crop watcher under: $BASE_DIR"
  mkdir -p "$SRC_DIR" "$DEST_DIR" "$MOVED_DIR"

  # === process_image: given one file path, crop it and move original ===
  process_image() {
    local input_file="$1"
    local filename="$(basename "$input_file")"
    local output_file="$DEST_DIR/$filename"

    echo "🔧 Processing '$filename'..."
    magick "$input_file" -crop "${WIDTH}x${HEIGHT}+${X}+${Y}" "$output_file"
    if [[ $? -eq 0 ]]; then
      mv "$input_file" "$MOVED_DIR"
      echo "✔ Saved: $output_file"
      echo "🔀 Moved original to $MOVED_DIR"
    else
      echo "❌ Failed to crop: $filename"
    fi
  }

  # === WATCH LOOP: poll for new .jpg/.jpeg files every POLL_INTERVAL seconds === 
  #extract out 
  shopt -s nullglob
  echo "Watching '$SRC_DIR' for new JPG/JPEG files (poll every $POLL_INTERVAL s)..."
  while true; do
    for f in "$SRC_DIR"/*.{jpg,jpeg,JPG,JPEG}; do
      [[ -f "$f" ]] || continue
      base="$(basename "$f")"
      [[ -f "$DEST_DIR/$base" ]] && continue
      process_image "$f"
    done

    printf "\nType 'exit' to quit; otherwise the watcher continues after %s seconds...\n" "$POLL_INTERVAL"
    read -t "$POLL_INTERVAL" cmd
    if [[ "$cmd" == "exit" ]]; then
      echo "Exiting image‐crop watcher..."
      break
    fi
  done
  shopt -u nullglob

  echo "Cleanup done. Returning to menu."
}

# 3.2) add_music_to_video: merges INPUT_VIDEO + MUSIC_FILE into a new file in OUTPUT_DIR
add_music_to_video() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  BASE_DIR="$SCRIPT_DIR"

  # load config file
  source "config-02-addmusic.txt"

  # === PATHS & SETTINGS ===
  INPUT_VIDEO="$BASE_DIR/02_gif_music/tempDisplay/input.mp4"
  OUTPUT_DIR="$BASE_DIR/02_gif_music/Output"
  MOVED_DIR="$BASE_DIR/02_gif_music/Moved"
  MUSIC_FILE="$BASE_DIR/02_gif_music/bg_music/background_music.mp3"

  # === INIT: create folders if they don’t exist ===
  echo "Initializing image-crop watcher under: $BASE_DIR"
  mkdir -p "$INPUT_VIDEO" "$OUTPUT_DIR" "$MOVED_DIR"

  # Make sure these variables were set in config.txt:
  #   INPUT_VIDEO, MUSIC_FILE, OUTPUT_DIR
  if [[ -z "$INPUT_VIDEO" || -z "$MUSIC_FILE" || -z "$OUTPUT_DIR" ]]; then
    echo "Error: INPUT_VIDEO, MUSIC_FILE, or OUTPUT_DIR not set in config.txt."
    return 1
  fi

  echo ">> Running add_music_to_video ..."
  echo "   Adding '$MUSIC_FILE' to '$INPUT_VIDEO'..."

  mkdir -p "$OUTPUT_DIR"

  ffmpeg -i "$INPUT_VIDEO" \
    -i "$MUSIC_FILE" \
    -c:v copy -c:a aac \
    -map 0:v:0 -map 1:a:0 \
    "${OUTPUT_DIR}/with_music_$(basename "$INPUT_VIDEO")"

  if [[ $? -ne 0 ]]; then
    echo "   [Error] ffmpeg failed to add music."
    return 1
  fi

  # === MOVE ORIGINAL VIDEO TO MOVED ===
  echo "🔀 Moving original to: $MOVED_DIR"
  mv "$INPUT_VIDEO" "$MOVED_DIR"

  echo "   (Music added — output in ${OUTPUT_DIR}/with_music_$(basename "$INPUT_VIDEO"))"
}

# 3.3) another_tool: placeholder for any additional functionality you want to add
another_tool() {
  echo ">> Running another_tool …"
  # Insert your custom logic here, or reference variables from config.txt
  sleep 1
  echo "   (another_tool complete)"
}

##############################
# 4) START THE SCRIPT
##############################

# Finally, call main_menu to begin.  All functions are now defined.
main_menu

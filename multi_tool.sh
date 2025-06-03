#!/usr/bin/
# 
#this is to let you pick which “tool” (function) to run,
# and reads variables from config.txt.

##############################
# 1) CONFIGURATION
##############################

# Path to your config file (adjust if necessary)
CONFIG_FILE="./config.txt"

# Check if config file exists; if not, exit with an error
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: config.txt not found at '$CONFIG_FILE'."
  echo "Create a config.txt with the necessary variables and rerun."
  exit 1
fi

# Source (import) all VARIABLE=VALUE lines from config.txt
# Assume config.txt consists of simple KEY=VALUE lines (cannot have spaces around the "=")
# e.g.:
#   CROP_WIDTH=1920
#   CROP_HEIGHT=1080
#   INPUT_VIDEO="input.mp4"
#   MUSIC_FILE="/path/to/music.mp3"
#   OUTPUT_DIR="./output"
source "$CONFIG_FILE"

##############################
# 2) FUNCTIONS (TOOLS)
##############################

# 2.1) Crop video function
crop_video() {
  # Example usage of variables from config.txt:
  #   CROP_WIDTH, CROP_HEIGHT, INPUT_VIDEO, OUTPUT_DIR
  echo ">> Running crop_video ..."
  echo "   Cropping '$INPUT_VIDEO' to ${CROP_WIDTH}x${CROP_HEIGHT}..."

  # (Replace with your actual ffmpeg/ImageMagick command, e.g.):
  # ffmpeg -i "$INPUT_VIDEO" -vf "crop=${CROP_WIDTH}:${CROP_HEIGHT}" \
  #        "${OUTPUT_DIR}/cropped_$(basename "$INPUT_VIDEO")"

  # For now, just simulate:
  sleep 1
  echo "   (cropping complete — output in ${OUTPUT_DIR})"
}

# 2.2) Add music to video function
add_music_to_video() {
  # Example usage of variables from config.txt:
  #   INPUT_VIDEO, MUSIC_FILE, OUTPUT_DIR
  echo ">> Running add_music_to_video ..."
  echo "   Adding '$MUSIC_FILE' to '$INPUT_VIDEO'..."

  # (Replace with your actual ffmpeg command, e.g.):
  # ffmpeg -i "$INPUT_VIDEO" -i "$MUSIC_FILE" -c:v copy -c:a aac \
  #        -map 0:v:0 -map 1:a:0 \
  #        "${OUTPUT_DIR}/with_music_$(basename "$INPUT_VIDEO")"

  # Simulate:
  sleep 1
  echo "   (music added — output in ${OUTPUT_DIR})"
}

# 2.3) Another example function
# e.g. resize image, convert format, etc.
another_tool() {
  # Use whatever variables you defined in config.txt
  echo ">> Running another_tool ..."
  # ...
  sleep 1
  echo "   (another_tool complete)"
}

##############################
# 3) MENU / USER INPUT
##############################

show_menu() {
  echo "---------------------------------"
  echo "   Choose a tool to run:"
  echo "     1) Crop image"
  echo "     2) Add music to video"
  echo "     3) Another tool (placeholder)"
  echo "     0) Exit"
  echo "---------------------------------"
  echo -n "Enter your choice [0-3]: "
}

# Main loop: show menu, read choice, dispatch
while true; do
  show_menu
  read -r CHOICE

  case "$CHOICE" in
    1)
      crop_video
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

  echo    # blank line for readability
done

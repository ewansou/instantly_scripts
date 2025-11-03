#!/bin/bash

# A script to watch a folder and apply ImageMagick commands, using an external watcher.

# --- BOOTSTRAP: Make the script self-aware and portable ---
# This ensures all paths are relative to the script's own location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# --- SETUP: Load the external watcher script ---
# This is the fix: Look for the watcher in the parent directory.
if [[ ! -f "../watcher.sh" ]]; then
  echo "❌ FATAL ERROR: watcher.sh not found in the parent directory."
  exit 1
fi
source "../watcher.sh"

############################################################
# SECTION 1: THE MAIN IMAGE CROPPING LOGIC
############################################################
#
# This is the main function that runs the tool.
#
crop_image_tool() {

  # --- 1. Load Configuration ---
  local CONFIG_FILE="./config-01-Crop.txt"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ ERROR: Config file not found at '$CONFIG_FILE'"
    return 1
  fi
  source "$CONFIG_FILE"

  # --- 2. Global Configs ---
  local SRC_DIR="./tempDisplay"
  local OUTPUT_DIR="./Output"
  local MOVED_DIR="./Moved"

  # --- 3. Validate that variables were loaded from config ---
  # This now checks for the COMMAND variable instead of IMAGICK_ARGS.
  if [[ -z "$COMMAND" || -z "$POLL_INTERVAL" ]]; then
    echo "❌ ERROR: A required variable (COMMAND or POLL_INTERVAL) is missing from '$CONFIG_FILE'."
    return 1
  fi

  # --- 4. Prepare Paths and Folders ---
  echo "Initializing folders: $SRC_DIR, $OUTPUT_DIR, $MOVED_DIR"
  mkdir -p "$SRC_DIR" "$OUTPUT_DIR" "$MOVED_DIR"

  # --- 5. Define the Process Function ---
  process_single_image() {
    local input_file="$1"
    local filename
    filename="$(basename "$input_file")"
    local output_file="$OUTPUT_DIR/$filename"

    echo "🔧 Processing '$filename'..."
    echo "   Running command from config: $COMMAND"

    # Execute the command string from the config file using eval.
    # This is less safe but matches your requested format.
    eval "$COMMAND"

    if [[ $? -eq 0 ]]; then
      echo "✔ Success! Saved to $output_file"
      mv "$input_file" "$MOVED_DIR"
    else
      echo "❌ Failed to process: $filename"
    fi
  }

  # --- 6. START THE WATCHER ---
  # Call the external watcher function with the 5 arguments it expects.
  watch_for_new_images \
    "$SRC_DIR" \
    "$OUTPUT_DIR" \
    "$POLL_INTERVAL" \
    "process_single_image" \
    "jpg,jpeg,png,gif,JPG,JPEG,PNG,GIF"
}

############################################################
# SECTION 2: START THE SCRIPT
############################################################
#
# This is the entry point that runs the main logic.
#
crop_image_tool

#!/bin/bash

# --- SETUP: Load watcher and get script's location ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# This assumes your watcher script is one level up and named 'watch_helper.sh'
source "$PARENT_DIR/watcher.sh"
if [[ ! -f "$SCRIPT_DIR/config-03-rotate-image.txt" ]]; then
    echo "❌ ERROR: config-03-rotate-image.txt not found in $SCRIPT_DIR"
    exit 1
fi
source "$SCRIPT_DIR/config-03-rotate-image.txt"
# This is the main function that will be called by your external menu
rotate_image() {

 

  # --- 2. Get User Input for Rotation Angle ---
  # This menu is internal to this function, as requested.
  local ROTATION_ANGLE
  while true; do
    cat <<EOF

  Please choose a rotation angle to apply to all images:
    1) 90 degrees clockwise
    2) 90 degrees anti-clockwise
    3) 180 degrees
    0) Cancel and return
EOF
    echo -n "  Enter your choice [0-3]: "
    read -r ROTATION_CHOICE

    case "$ROTATION_CHOICE" in
      1) ROTATION_ANGLE="90" ; break ;;
      2) ROTATION_ANGLE="-90"; break ;;
      3) ROTATION_ANGLE="180"; break ;;
      0) echo "Operation cancelled."; return ;;
      *) echo "  Invalid choice. Please enter 0-3." ;;
    esac
  done

  # --- 3. Prepare Paths and Folders ---
  # Use the paths from the config file. Do not hard-code them here.
  # This makes the script respect your config.txt settings.
    # Construct the FULL paths for all operations
    local FULL_SRC_DIR="$PARENT_DIR/$SRC_DIR"
    local FULL_OUTPUT_DIR="$PARENT_DIR/$OUTPUT_DIR"
    local FULL_MOVED_DIR="$PARENT_DIR/$MOVED_DIR"

    # Create the necessary directories
    mkdir -p "$FULL_SRC_DIR" "$FULL_OUTPUT_DIR" "$FULL_MOVED_DIR"

  # --- 4. Define the Process Function ---
  # This is where the rotation logic you wanted is added.
  process() {
    local input_file="$1"
    local output_file="$DEST_DIR/$(basename "$input_file")"

    # Construct the FULL paths for all operations
    local FULL_SRC_DIR="$PARENT_DIR/$SRC_DIR"
    local FULL_OUTPUT_DIR="$PARENT_DIR/$OUTPUT_DIR"
    local FULL_MOVED_DIR="$PARENT_DIR/$MOVED_DIR"

    # Create the necessary directories
    mkdir -p "$FULL_SRC_DIR" "$FULL_OUTPUT_DIR" "$FULL_MOVED_DIR"
    
    echo "🔧 Rotating '$(basename "$input_file")' by ${ROTATION_ANGLE} degrees..."

    # The core ImageMagick command to rotate the image
    magick "$input_file" -rotate "$ROTATION_ANGLE" "$output_file"

    # Check if the last command was successful
    if [[ $? -eq 0 ]]; then
      echo "✔ Success. Moving original file."
      mv "$input_file" "$MOVED_DIR"
    else
      echo "❌ ERROR: ImageMagick command failed for '$input_file'."
    fi
  }

  # --- 5. START THE WATCHER ---
  # Call the watcher with the correct arguments for this tool.
  echo "Applying a ${ROTATION_ANGLE}° rotation to all new images."
  watch_for_new_images \
    "$SRC_DIR" \
    "$DEST_DIR" \
    "$POLL_INTERVAL" \
    "process" \
    "jpg,jpeg,JPG,JPEG,png,PNG"
}

# --- This line runs the function when the script is executed ---
rotate_image
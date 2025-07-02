#!/bin/bash

# --- SETUP: Load watcher and get script's location ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# This assumes your watcher script is one level up and named 'watcher.sh'
if [[ -f "$PARENT_DIR/watcher.sh" ]]; then
    source "$PARENT_DIR/watcher.sh"
else
    echo "❌ FATAL ERROR: watcher.sh not found in parent directory."
    exit 1
fi

# This is the main function that will be called by your external menu
rotate_image() {

    # --- 1. Load Configuration ---
    # This is the fix: Using the correct config filename.
    local CONFIG_FILE="$SCRIPT_DIR/config-03-rotate-image.txt"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "❌ ERROR: Config file not found at '$CONFIG_FILE'"
        return 1
    fi
    source "$CONFIG_FILE"

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

        # DEBUG: Show what value was read from the user's input
        echo "DEBUG: User entered: '$ROTATION_CHOICE'"

        case "$ROTATION_CHOICE" in
        1)
            echo "DEBUG: Matched choice 1."
            ROTATION_ANGLE="90"
            break
            ;;
        2)
            echo "DEBUG: Matched choice 2."
            ROTATION_ANGLE="-90"
            break
            ;;
        3)
            echo "DEBUG: Matched choice 3."
            ROTATION_ANGLE="180"
            break
            ;;
        0)
            echo "Operation cancelled."
            return
            ;;
        *)
            echo "  Invalid choice. Please enter 0-3."
            ;;
        esac
    done

    # --- 3. Prepare Paths and Folders ---
    # This creates absolute paths based on the script's location.
    echo "Initializing folders..."
    local FULL_SRC_DIR="$SCRIPT_DIR/$SRC_DIR"
    local FULL_DEST_DIR="$SCRIPT_DIR/$DEST_DIR"
    local FULL_MOVED_DIR="$SCRIPT_DIR/$MOVED_DIR"
    mkdir -p "$FULL_SRC_DIR" "$FULL_DEST_DIR" "$FULL_MOVED_DIR"

    # --- 4. Define the Process Function ---
    # This is where the rotation logic you wanted is added.
    process() {
        local input_file="$1"
        # Use the full path for the output file
        local output_file="$FULL_DEST_DIR/$(basename "$input_file")"

        # DEBUG: Show the angle being used just before the command runs
        echo "DEBUG: The 'process' function is using ROTATION_ANGLE: '$ROTATION_ANGLE'"
        echo "🔧 Rotating '$(basename "$input_file")' by ${ROTATION_ANGLE} degrees..."

        # The core ImageMagick command to rotate the image
        magick "$input_file" -rotate "$ROTATION_ANGLE" "$output_file"

        # Check if the last command was successful
        if [[ $? -eq 0 ]]; then
            echo "✔ Success. Moving original file."
            # Use the full path for the moved file
            mv "$input_file" "$FULL_MOVED_DIR"
        else
            echo "❌ ERROR: ImageMagick command failed for '$input_file'."
        fi
    }

    # --- 5. START THE WATCHER ---
    # Call the watcher with the correct, full paths.
    echo "Applying a ${ROTATION_ANGLE}° rotation to all new images."
    watch_for_new_images \
        "$FULL_SRC_DIR" \
        "$FULL_DEST_DIR" \
        "$POLL_INTERVAL" \
        "process" \
        "jpg,jpeg,JPG,JPEG,png,PNG"
}

# --- This line runs the function when the script is executed ---
rotate_image

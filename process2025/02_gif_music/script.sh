#!/bin/bash

# --- SETUP AND LOAD CONFIG ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the helper and the config file
source "$PARENT_DIR/watcher.sh"
if [[ ! -f "$SCRIPT_DIR/config-02-addmusic.txt" ]]; then
    echo "❌ ERROR: config-02-addmusic.txt not found in $SCRIPT_DIR"
    exit 1
fi
source "$SCRIPT_DIR/config-02-addmusic.txt"

# This function contains the main logic
add_music() {
    # --- VALIDATE AND DEBUG ---
    echo "--- Settings Loaded from Config ---"
    echo "  Source Directory: $SRC_DIR"
    echo "  Output Directory: $OUTPUT_DIR"
    echo "  Moved Directory:  $MOVED_DIR"
    echo "  Music File:       $MUSIC_FILE"
    echo "-----------------------------------"

    # Construct the FULL paths for all operations
    local FULL_SRC_DIR="$PARENT_DIR/$SRC_DIR"
    local FULL_OUTPUT_DIR="$PARENT_DIR/$OUTPUT_DIR"
    local FULL_MOVED_DIR="$PARENT_DIR/$MOVED_DIR"
    local FULL_MUSIC_FILE="$PARENT_DIR/$MUSIC_FILE"

    # Create the necessary directories
    mkdir -p "$FULL_SRC_DIR" "$FULL_OUTPUT_DIR" "$FULL_MOVED_DIR"

    # --- DEFINE THE PROCESSOR FUNCTION ---
    process_video() {
        local input_file="$1"
        local filename
        filename="$(basename "$input_file")"
        local output_file="$FULL_OUTPUT_DIR/$filename"

        # This is the safe way to handle command arguments from a config file
        local -a args_array
        read -r -a args_array <<< "$FFMPEG_ARGS"

        echo "🎵 Processing '$filename'..."

        # Execute the command safely, without eval, can remove "-loglevel error" to see the version banner, configuration details, stream mapping, and the live progress bar
        ffmpeg -y -loglevel error -i "$input_file" -i "$FULL_MUSIC_FILE" \ 
               "${args_array[@]}" \
               "$output_file"

        if [[ $? -eq 0 ]]; then
            echo "✔ Success! Saved to $output_file"
            mv "$input_file" "$FULL_MOVED_DIR"
        else
            echo "❌ Failed to process: $filename"
        fi
    }

    # --- START THE WATCHER ---
    watch_for_new_images \
        "$FULL_SRC_DIR" \
        "$FULL_OUTPUT_DIR" \
        "$POLL_INTERVAL" \
        "process_video" \
        "mp4,MP4,mov,mkv,avi"
}

# --- RUN THE SCRIPT ---
add_music
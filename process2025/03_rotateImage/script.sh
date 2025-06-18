#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PARENT_DIR/watch_helper.sh"

add_music() {

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/config.txt"

  #Display what is in the config file



  POLL_INTERVAL=5

  echo "Initializing folders under: $SCRIPT_DIR"
  mkdir -p "$SRC_DIR" "$DEST_DIR" "$MOVED_DIR"

  process() {
  }

  watch_for_new_images 
}

add_music
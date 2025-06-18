#!/usr/bin/env bash

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

main_menu() {
  while true; do
    show_menu
    read -r CHOICE

    case "$CHOICE" in
      1)
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        bash "$SCRIPT_DIR/01_cropImage/script.sh"
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

main_menu
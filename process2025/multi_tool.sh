#!/usr/bin/env bash

##############################
#MENU LOGIC
##############################

# 1) show_menu: prints the options to screen
show_menu() {
  echo "---------------------------------"
  echo "   Choose a tool to run:"
  echo "     1) Crop image "
  echo "     2) Add music to video"
  echo "     3) Rotate Image"
  echo "     0) Exit"
  echo "---------------------------------"
  echo -n "Enter your choice [0-3]: "
}

#2) main_menu: the loop that reads your choice and dispatches to the correct function
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
      SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
      bash "$SCRIPT_DIR/02_gif_music/script.sh"
      ;;
    3)
      SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
      bash "$SCRIPT_DIR/03_rotate_image/script.sh"
      ;;
    0)
      echo "Exiting. Goodbye!"
      exit 0
      ;;
    *)
      echo "Invalid choice. Please enter 0, 1, 2, or 3."
      ;;
    esac

    echo # blank line for readability before showing menu again
  done
}

main_menu

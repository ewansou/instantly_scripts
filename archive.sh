#!/bin/bash

# Revolve Archiving Script (With Try Again Feature)

# ==== CONFIGURABLE PATHS ====
DESKTOP_PATH=~/Desktop
DROPBOX_PATH=~/Dropbox/Operations/ForCharmaine/R360
ARC_PATH=~/Desktop/ARC/Year2025
SOURCE_DONE_MP4="$DESKTOP_PATH/doneMP4"
# =============================

echo ""
echo "Launching Revolve Archiving Script..."
echo ""

# 1. Loop until Dropbox is available
while true; do
  # Check Dropbox
  if [[ ! -d "$DROPBOX_PATH" ]]; then
    echo "⚠️ Error: Dropbox not connected. Please check connection."
    read -p "Retry? (Y/N): " RETRY
    if [[ ! $RETRY =~ ^[yY](es)?$ ]]; then
      echo "Aborted."
      exit 1
    fi
  else
    break
  fi
done

# 2. Get Event ID
read -p "Enter the Event ID: " EVENT_ID

# 3. Validate Event ID
if [[ -z "$EVENT_ID" ]]; then
  echo "⚠️ Error: Event ID cannot be empty."
  exit 1
fi

# 4. Define final destinations
DROPBOX_EVENT_PATH="$DROPBOX_PATH/$EVENT_ID"
ARC_EVENT_PATH="$ARC_PATH/$EVENT_ID"

# 5. Confirm move
echo ""
echo "Moving doneMP4 to: $DROPBOX_EVENT_PATH"
echo "Moving all other files to: $ARC_EVENT_PATH"
read -p "Proceed? (Y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[yY](es)?$ ]]; then
  echo "Aborted."
  exit 1
fi

# 6. Create folders
mkdir -p "$DROPBOX_EVENT_PATH"
mkdir -p "$ARC_EVENT_PATH"

# 7. Move doneMP4
if [[ -d "$SOURCE_DONE_MP4" ]]; then
  echo ""
  echo "Moving 'doneMP4' to Dropbox..."
  mv -v "$SOURCE_DONE_MP4" "$DROPBOX_EVENT_PATH"
else
  echo "⚠️ Warning: 'doneMP4' folder not found. Skipping."
fi

# 8. Move other files
echo ""
echo "Moving other Desktop items to ARC..."

for item in "$DESKTOP_PATH"/*; do
  BASENAME=$(basename "$item")

  # Skip ARC folder, Dropbox shortcut, doneMP4 (already moved)
  if [[ "$BASENAME" == "ARC" || "$BASENAME" == "Dropbox" || "$BASENAME" == "doneMP4" ]]; then
    continue
  fi

  mv -v "$item" "$ARC_EVENT_PATH"
done

# 9. Done
echo ""
echo "✅ Archiving Complete for Event ID: $EVENT_ID"
echo ""
read -p "Press Enter to exit..."

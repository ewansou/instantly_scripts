#!/bin/bash

# Revolve Archiving Script (Final Version - Display to Dropbox, Rest to ARC)

# ==== CONFIGURABLE PATHS ====
DESKTOP_PATH=~/Desktop
DROPBOX_PATH=~/Dropbox/Operations/ForCharmaine/R360
ARC_PATH=~/Desktop/ARC/Year2025
SOURCE_DONE_MP4="$DESKTOP_PATH/doneMP4"
SOURCE_HOLD="$DESKTOP_PATH/Hold"
SOURCE_OVERLAY="$DESKTOP_PATH/overlay.psd"
SOURCE_BACKGROUND="$DESKTOP_PATH/background.jpg"
SOURCE_DISPLAY="$DESKTOP_PATH/Display"
# =============================

echo ""
echo "Launching Revolve Archiving Script..."
echo ""

# 1. Loop until Dropbox is available
while true; do
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
echo "Moving 'Display' to Dropbox path: $DROPBOX_EVENT_PATH"
echo "Moving 'doneMP4', 'Hold', 'overlay.psd', 'background.jpg' to ARC path: $ARC_EVENT_PATH"
read -p "Proceed? (Y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[yY](es)?$ ]]; then
  echo "Aborted."
  exit 1
fi

# 6. Create folders
mkdir -p "$DROPBOX_EVENT_PATH"
mkdir -p "$ARC_EVENT_PATH"

# 7. Move Display to Dropbox
if [[ -d "$SOURCE_DISPLAY" ]]; then
  echo ""
  echo "Moving 'Display' to Dropbox..."
  mv -v "$SOURCE_DISPLAY" "$DROPBOX_EVENT_PATH"
else
  echo "⚠️ Warning: 'Display' folder not found. Skipping."
fi

# 8. Move doneMP4 to ARC
if [[ -d "$SOURCE_DONE_MP4" ]]; then
  echo ""
  echo "Moving 'doneMP4' to ARC..."
  mv -v "$SOURCE_DONE_MP4" "$ARC_EVENT_PATH"
else
  echo "⚠️ Warning: 'doneMP4' folder not found. Skipping."
fi

# 9. Move Hold to ARC
if [[ -d "$SOURCE_HOLD" ]]; then
  echo ""
  echo "Moving 'Hold' to ARC..."
  mv -v "$SOURCE_HOLD" "$ARC_EVENT_PATH"
else
  echo "⚠️ Warning: 'Hold' folder not found. Skipping."
fi

# 10. Move overlay.psd to ARC
if [[ -f "$SOURCE_OVERLAY" ]]; then
  echo ""
  echo "Moving 'overlay.psd' to ARC..."
  mv -v "$SOURCE_OVERLAY" "$ARC_EVENT_PATH"
else
  echo "⚠️ Warning: 'overlay.psd' not found. Skipping."
fi

# 11. Move background.jpg to ARC
if [[ -f "$SOURCE_BACKGROUND" ]]; then
  echo ""
  echo "Moving 'background.jpg' to ARC..."
  mv -v "$SOURCE_BACKGROUND" "$ARC_EVENT_PATH"
else
  echo "⚠️ Warning: 'background.jpg' not found. Skipping."
fi

# 12. Done
echo ""
echo "✅ Archiving Complete for Event ID: $EVENT_ID"
echo ""
read -p "Press Enter to exit..."

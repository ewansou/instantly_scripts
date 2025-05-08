#!/bin/bash

# Revolve Archiving Script (With Folder Conflict Checks and Logging,FINAL)

# ==== CONFIGURABLE PATHS ====
HOME_PATH=$HOME
DESKTOP_PATH="$HOME_PATH/Desktop"
DROPBOX_BASE="$HOME_PATH/Dropbox"
DROPBOX_ROOT_PATH="$DROPBOX_BASE/Operations/ForCharmaine/R360"
DATE_TAG=$(date +%Y%m%d)

# SOURCE PATHING
SOURCE_DONE_MP4="/c/DzenTech/Spinner360-VFX/Outputs/DoneMP4"
SOURCE_HOLD="$DESKTOP_PATH/Hold"
SOURCE_OVERLAY="$DESKTOP_PATH/overlay.png"
SOURCE_BACKGROUND="/c/Users/ewans/Desktop/background.jpg"
SOURCE_DISPLAY="$DESKTOP_PATH/Display"
# =============================

echo ""
echo "Launching Revolve Archiving Script..."
echo ""

# ==== FUNCTION: MOVE FILE OR FOLDER ====
move_item() {
  local src="$1"
  local dst="$2"
  local name=$(basename "$src")

  if [[ -e "$src" ]]; then
    echo "📦 Moving '$name' to $(basename "$dst")..."
    mv -v "$src" "$dst"
  else
    echo "⚠️ '$name' not found. Skipping."
  fi
}
# =======================================

# 2. Get Event ID
read -p "Enter the Event ID: " EVENT_ID
if [[ -z "$EVENT_ID" ]]; then
  echo "⚠️ Error: Event ID cannot be empty."
  read -p "Press Enter to exit..."
  exit 1
fi

# 3. Define Target Paths
BASE_ARC_FOLDER="$DESKTOP_PATH/ARC/${DATE_TAG}_${EVENT_ID}"
ARC_EVENT_FOLDER="$BASE_ARC_FOLDER"
BASE_DROPBOX_FOLDER="$DROPBOX_ROOT_PATH/$EVENT_ID"
DROPBOX_EVENT_PATH="$BASE_DROPBOX_FOLDER"

# 4. Check for Existing ARC Folder
if [[ -d "$ARC_EVENT_FOLDER" ]]; then
  echo "⚠️ ARC folder already exists: $ARC_EVENT_FOLDER"
  read -p "Do you want to overwrite/merge this folder? (Y/N): " OVERWRITE_CONFIRM
  if [[ "$OVERWRITE_CONFIRM" =~ ^[nN]$ ]]; then
    suffix="_updated"
    attempt=1
    ARC_EVENT_FOLDER="${BASE_ARC_FOLDER}${suffix}"
    while [[ -d "$ARC_EVENT_FOLDER" ]]; do
      suffix="_updated_v$attempt"
      ARC_EVENT_FOLDER="${BASE_ARC_FOLDER}${suffix}"
      attempt=$((attempt + 1))
    done
    echo "📁 A new ARC folder will be created as: $ARC_EVENT_FOLDER"
  fi
fi

# 5. Check for Existing Dropbox Folder
if [[ -d "$DROPBOX_EVENT_PATH" ]]; then
  echo "⚠️ Dropbox folder already exists: $DROPBOX_EVENT_PATH"
  read -p "Do you want to overwrite/merge this folder? (Y/N): " DROPBOX_CONFIRM
  if [[ "$DROPBOX_CONFIRM" =~ ^[nN]$ ]]; then
    suffix="_updated"
    attempt=1
    DROPBOX_EVENT_PATH="${BASE_DROPBOX_FOLDER}${suffix}"
    while [[ -d "$DROPBOX_EVENT_PATH" ]]; do
      suffix="_updated_v$attempt"
      DROPBOX_EVENT_PATH="${BASE_DROPBOX_FOLDER}${suffix}"
      attempt=$((attempt + 1))
    done
    echo "📁 A new Dropbox folder will be created as: $DROPBOX_EVENT_PATH"
  fi
fi

# 6. Check Required Files/Folders
echo ""
echo "Checking for required files/folders..."
for file in "$SOURCE_DISPLAY" "$SOURCE_DONE_MP4" "$SOURCE_HOLD" "$SOURCE_OVERLAY" "$SOURCE_BACKGROUND"; do
  if [[ ! -e "$file" ]]; then
    echo "❌ Required item not found: $(basename "$file")"
    read -p "Press Enter to exit..."
    exit 1
  fi
done

# 7. Confirm Move
echo ""
echo "✅ All required items found."
echo "Files will be moved to:"
echo "  Dropbox: $DROPBOX_EVENT_PATH"
echo "  ARC:     $ARC_EVENT_FOLDER"
read -p "Proceed? (Y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
  echo "Aborted."
  read -p "Press Enter to exit..."
  exit 1
fi

# 8. Create Target Folders
mkdir -p "$DROPBOX_EVENT_PATH"
mkdir -p "$ARC_EVENT_FOLDER"

# 9. Perform Move Actions
echo ""

# -- Display: move only contents into a new "Display" subfolder on Dropbox
mkdir -p "$DROPBOX_EVENT_PATH/Display"
mv -v "$SOURCE_DISPLAY"/* "$DROPBOX_EVENT_PATH/Display"/

# -- DoneMP4: move only contents into a new "DoneMP4" subfolder in ARC
mkdir -p "$ARC_EVENT_FOLDER/DoneMP4"
mv -v "$SOURCE_DONE_MP4"/* "$ARC_EVENT_FOLDER/DoneMP4"/

# -- Hold: move only contents into a new "Hold" subfolder in ARC
mkdir -p "$ARC_EVENT_FOLDER/Hold"
mv -v "$SOURCE_HOLD"/* "$ARC_EVENT_FOLDER/Hold"/


# -- Other items (whole files)
move_item "$SOURCE_OVERLAY"    "$ARC_EVENT_FOLDER"
move_item "$SOURCE_BACKGROUND" "$ARC_EVENT_FOLDER"

# 10. Logging
LOG_FILE="$ARC_EVENT_FOLDER/archive_log.txt"
{
  echo "====== Instantly.sg Archiving Log ======"
  echo "Event ID: $EVENT_ID"
  echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "ARC Folder Path: $ARC_EVENT_FOLDER"
  echo "Dropbox Folder Path: $DROPBOX_EVENT_PATH"
  echo "Moved Files:"
  echo "- Display contents → Dropbox/Display"
  echo "- DoneMP4 contents → ARC/DoneMP4"
  echo "- Hold → ARC"
  echo "- overlay.png → ARC"
  echo "- background.jpg → ARC"
} > "$LOG_FILE"

# 11. Done
echo ""
echo "✅ Archiving Complete: $DATE_TAG - $EVENT_ID"
echo "📝 Log saved at: $LOG_FILE"
read -p "Press Enter to exit..."

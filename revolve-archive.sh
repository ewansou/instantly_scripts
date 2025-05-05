#!/bin/bash

# Revolve Archiving Script (Strict Validation - No Skipping, With Dropbox Sync Check, Versioning, and Logging)

# ==== CONFIGURABLE PATHS ====
HOME_PATH=$HOME
DESKTOP_PATH="$HOME_PATH/Desktop"
DROPBOX_BASE="$HOME_PATH/Dropbox"
DROPBOX_ROOT_PATH="$DROPBOX_BASE/Operations/ForCharmaine/R360"
DATE_TAG=$(date +%Y%m%d)

SOURCE_DONE_MP4="$DESKTOP_PATH/doneMP4"
SOURCE_HOLD="$DESKTOP_PATH/Hold"
SOURCE_OVERLAY="$DESKTOP_PATH/overlay.psd"
SOURCE_BACKGROUND="$DESKTOP_PATH/background.jpg"
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

# 1. Validate Dropbox Connection, Folder, and Sync Status
while true; do
  ERROR=0

  if [[ ! -d "$DROPBOX_BASE" ]]; then
    echo "❌ Dropbox is not connected at: $DROPBOX_BASE"
    ERROR=1
  fi

  if [[ ! -d "$DROPBOX_ROOT_PATH" ]]; then
    echo "❌ Dropbox path '$DROPBOX_ROOT_PATH' not found. Check that the folder exists."
    ERROR=1
  fi

  if command -v dropbox &> /dev/null; then
    SYNC_STATUS=$(dropbox status)
    if [[ "$SYNC_STATUS" != "Up to date" ]]; then
      echo "⚠️ Dropbox is currently syncing: $SYNC_STATUS"
      echo "Please wait for it to finish syncing."
      ERROR=1
    fi
  else
    echo "⚠️ Dropbox CLI not found. Skipping sync status check."
  fi

  if [[ "$ERROR" -eq 1 ]]; then
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
if [[ -z "$EVENT_ID" ]]; then
  echo "⚠️ Error: Event ID cannot be empty."
  exit 1
fi

# 3. Define ARC and Dropbox Target Paths
BASE_ARC_FOLDER="$DESKTOP_PATH/ARC/${DATE_TAG}_${EVENT_ID}"
ARC_EVENT_FOLDER="$BASE_ARC_FOLDER"

BASE_DROPBOX_FOLDER="$DROPBOX_ROOT_PATH/$EVENT_ID"
DROPBOX_EVENT_PATH="$BASE_DROPBOX_FOLDER"

# 4. Check for ARC folder conflict
if [[ -d "$ARC_EVENT_FOLDER" ]]; then
  echo "⚠️ ARC folder already exists: $ARC_EVENT_FOLDER"
  read -p "Do you want to overwrite/merge this folder? (Y/N): " OVERWRITE_CONFIRM

  if [[ "$OVERWRITE_CONFIRM" =~ ^[nN]$ ]]; then
    suffix="_updated"
    attempt=1
    ARC_EVENT_FOLDER="${BASE_ARC_FOLDER}${suffix}"
    while [[ -d "$ARC_EVENT_FOLDER" ]]; do
      attempt=$((attempt + 1))
      suffix="_updated_v$attempt"
      ARC_EVENT_FOLDER="${BASE_ARC_FOLDER}${suffix}"
    done
    echo "📁 A new ARC folder will be created as: $ARC_EVENT_FOLDER"
  fi
fi

# 5. Check for Dropbox folder conflict
if [[ -d "$DROPBOX_EVENT_PATH" ]]; then
  echo "⚠️ Dropbox folder already exists: $DROPBOX_EVENT_PATH"
  read -p "Do you want to overwrite/merge this folder? (Y/N): " DROPBOX_OVERWRITE_CONFIRM

  if [[ "$DROPBOX_OVERWRITE_CONFIRM" =~ ^[nN]$ ]]; then
    suffix="_updated"
    attempt=1
    DROPBOX_EVENT_PATH="${BASE_DROPBOX_FOLDER}${suffix}"
    while [[ -d "$DROPBOX_EVENT_PATH" ]]; do
      attempt=$((attempt + 1))
      suffix="_updated_v$attempt"
      DROPBOX_EVENT_PATH="${BASE_DROPBOX_FOLDER}${suffix}"
    done
    echo "📁 A new Dropbox folder will be created as: $DROPBOX_EVENT_PATH"
  fi
fi

# 6. Check that ALL source files/folders exist
echo ""
echo "Checking for required files/folders..."

for file in "$SOURCE_DISPLAY" "$SOURCE_DONE_MP4" "$SOURCE_HOLD" "$SOURCE_OVERLAY" "$SOURCE_BACKGROUND"; do
  if [[ ! -e "$file" ]]; then
    echo "❌ Required file/folder '$(basename "$file")' not found on Desktop."
    exit 1
  fi
done

# 7. Confirm move
echo ""
echo "✅ All required items are present."
echo "Moving 'Display' to Dropbox: $DROPBOX_EVENT_PATH"
echo "Moving others to ARC: $ARC_EVENT_FOLDER"
read -p "Proceed? (Y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[yY](es)?$ ]]; then
  echo "Aborted."
  exit 1
fi

# 8. Create target folders
mkdir -p "$DROPBOX_EVENT_PATH"
mkdir -p "$ARC_EVENT_FOLDER"

# 9. Move using DRY principle
echo ""
move_item "$SOURCE_DISPLAY" "$DROPBOX_EVENT_PATH"
move_item "$SOURCE_DONE_MP4" "$ARC_EVENT_FOLDER"
move_item "$SOURCE_HOLD" "$ARC_EVENT_FOLDER"
move_item "$SOURCE_OVERLAY" "$ARC_EVENT_FOLDER"
move_item "$SOURCE_BACKGROUND" "$ARC_EVENT_FOLDER"

# 10. Create archive log
LOG_FILE="$ARC_EVENT_FOLDER/archive_log.txt"
{
  echo "====== Instantly.sg Archiving Log ======"
  echo "Event ID: $EVENT_ID"
  echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  echo "ARC Folder Path: $ARC_EVENT_FOLDER"
  echo "Dropbox Folder Path: $DROPBOX_EVENT_PATH"
  echo ""
  echo "Files moved:"
  echo "- Display → Dropbox"
  echo "- doneMP4 → ARC"
  echo "- Hold → ARC"
  echo "- overlay.psd → ARC"
  echo "- background.jpg → ARC"
} > "$LOG_FILE"

# 11. Done
echo ""
echo "✅ Archiving Complete: $DATE_TAG - $EVENT_ID"
echo "📝 Log saved to: $LOG_FILE"
read -p "Press Enter to exit..."

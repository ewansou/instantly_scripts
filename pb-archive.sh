#!/usr/bin/env bash

# Photobooth Archiving Script (with logging, versioning, and DRY principles)

# ==== CONFIGURATION ====
dropboxPhotoBootNewFolder="D:/Dropbox/Operations/#thisweek/NEWRADEN/photobooth-new"
mainPathToArchive="C:/Users/ewans/Desktop"
DATE_TAG=$(date +%d%m%Y)

SOURCE_DISPLAY="$mainPathToArchive/Display"
SOURCE_HOLD="$mainPathToArchive/Hold"
SOURCE_DONE="$mainPathToArchive/Done"
SOURCE_EDITED="$mainPathToArchive/Edited"
SOURCE_ARC="$mainPathToArchive/ARC"
# ========================

# ==== MOVE FUNCTION ====
move_item() {
  local src="$1"
  local dst="$2"
  local name
  name=$(basename "$src")

  if [[ ! -e "$src" ]]; then
    echo "⚠️  '$name' not found. Skipping." | tee -a "$logFile"
    return
  fi

  if [[ -d "$src" && -z "$(find "$src" -maxdepth 1 -not -type d)" ]]; then
    echo "⚠️  '$name' is empty. Skipping." | tee -a "$logFile"
    return
  fi

  mkdir -p "$dst"
  echo "📦 Moving '$name' to: $(basename "$dst")..." | tee -a "$logFile"
  mv -v "$src" "$dst" | tee -a "$logFile"
}
# ========================

# ==== MAIN LOOP ====
while true; do
  echo "==============================="
  echo "📅 STEP 1: Enter the Event ID (e.g., knoxx123):"
  read -rp "" eventId

  if [[ -z "$eventId" ]]; then
    echo "⚠️  Event ID is empty. Please try again."
    continue
  fi

  echo "You entered: $eventId"
  echo "⚠️  Please confirm. Type 'y' to continue, 'n' to retry."
  read -rp "" confirm

  case "$confirm" in
    y|Y)
      echo "==============================="
      echo "🚀 Archiving files in progress..."
      echo "==============================="

      eventFolderName="${DATE_TAG}_${eventId}"
      targetPath="$dropboxPhotoBootNewFolder/$eventFolderName"

      # Versioning logic
      if [[ -d "$targetPath" ]]; then
        suffix="_updated"
        attempt=1
        while [[ -d "${targetPath}${suffix}" ]]; do
          attempt=$((attempt + 1))
          suffix="_updated_v$attempt"
        done
        targetPath="${targetPath}${suffix}"
        eventFolderName="${eventFolderName}${suffix}"
        echo "📁 Using new versioned folder: $eventFolderName"
      fi

      mkdir -p "$targetPath"
      logFile="$targetPath/archive_log.txt"

      {
        echo "====== Instantly.sg Photobooth Archive Log ======"
        echo "Event ID: $eventId"
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Archived To: $targetPath"
        echo ""
        echo "Files moved:"
      } > "$logFile"

      # === MOVE FOLDERS ===
      echo ""
      move_item "$SOURCE_DISPLAY" "$targetPath/Display"
      move_item "$SOURCE_HOLD" "$targetPath/Hold"
      move_item "$SOURCE_DONE" "$targetPath/Done"
      move_item "$SOURCE_EDITED" "$targetPath/Edited"
      move_item "$SOURCE_ARC" "$targetPath/ARC"

      echo ""
      echo "✅ Archiving Complete: $eventId"
      echo "📝 Log saved to: $logFile"
      echo "📌 Ensure Dropbox finishes syncing before shutdown."
      echo "==============================="

      for i in 5 4 3 2 1; do
        echo "⏳ Exiting in $i..."
        sleep 1
      done

      exit 0
      ;;
    n|N)
      echo "🔁 Let's try again."
      ;;
    *)
      echo "❌ Invalid input. Please enter 'y' or 'n'."
      ;;
  esac
done

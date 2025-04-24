#!/bin/bash

# ==== CONFIGURABLE PATHS ====
desktop_path=~/Desktop
source_doneMP4="$desktop_path/doneMP4"
source_hold="$desktop_path/Hold"
template_file="$desktop_path/original_template.psd"

# These will be updated after reading event ID
event_folder=""
event_doneMP4=""
event_hold=""
# ============================

echo "Launching Revolve Archiving Script..."
echo ""

# Ask for event ID
read -p "Enter the event ID: " event_id

# Setup event-specific paths
event_folder="$desktop_path/$event_id"
event_doneMP4="$event_folder/doneMP4"
event_hold="$event_folder/Hold"

# Confirmation prompt
read -p "Continue? (Y/N): " confirm
if [[ ! $confirm =~ ^[yY](es)?$ ]]; then
  echo "Aborted."
  exit 1
fi

# Create event folders
mkdir -p "$event_doneMP4" "$event_hold"

# Move files
echo "Moving doneMP4 files..."
mv -v "$source_doneMP4"/* "$event_doneMP4" 2>/dev/null

echo "Moving Hold files..."
mv -v "$source_hold"/* "$event_hold" 2>/dev/null

echo "Moving original_template.psd..."
mv -v "$template_file" "$event_folder" 2>/dev/null

echo ""
echo "✅ Archiving complete for event: $event_id"
echo "Files are stored in: $event_folder"

# Pause before exit
read -p "Press Enter to exit..."

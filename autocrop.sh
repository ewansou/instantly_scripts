#!/bin/bash
# autocrop.sh
# Crops white borders from all JPEG/JPG images in ~/Desktop/Source to ~/Desktop/Moved,
# then removes default pixels from the top, left, and right sides. Pauses on errors or exit.
# Usage: ./autocrop.sh

# === CONFIGURABLE PATHS ===
SRC_DIR="$HOME/Desktop/Source"
DEST_DIR="$HOME/Desktop/Moved"
FUZZ="50%"               # Tolerance for near-white pixels

# === DEFAULT CROP VALUES ===
DEFAULT_TOP="18"         # Pixels to remove from the top edge
DEFAULT_LEFT="20"        # Pixels to remove from the left side
DEFAULT_RIGHT="20"       # Pixels to remove from the right side

# === FIND AND PROCESS ALL IMAGES ===
shopt -s nullglob
IMAGES=("$SRC_DIR"/*.{jpg,jpeg,JPG,JPEG})
shopt -u nullglob

if [[ ${#IMAGES[@]} -eq 0 ]]; then
  echo "No JPEG images found in $SRC_DIR"
  read -p "Press Enter to exit..."
  exit 0
fi

mkdir -p "$DEST_DIR"
echo "Found ${#IMAGES[@]} image(s). Starting batch crop..."

for INPUT_FILE in "${IMAGES[@]}"; do
  BASENAME="$(basename "$INPUT_FILE")"
  OUTPUT_FILE="$DEST_DIR/$BASENAME"

  echo "🔧 Processing '$BASENAME'..."
  echo "Applying default crop: top=${DEFAULT_TOP}px, left=${DEFAULT_LEFT}px, right=${DEFAULT_RIGHT}px"

  if magick "$INPUT_FILE" \
       -auto-orient \
       -background white -alpha remove -alpha off \
       -fuzz "$FUZZ" \
       -trim +repage \
       -gravity North -chop 0x${DEFAULT_TOP} \
       -gravity West  -chop ${DEFAULT_LEFT}x0 \
       -gravity East  -chop ${DEFAULT_RIGHT}x0 \
       "$OUTPUT_FILE"; then
    echo "✔ Saved: $OUTPUT_FILE"
  else
    echo "❌ Failed: $BASENAME"
    read -p "Press Enter to continue..."
  fi
done

echo "✅ Batch processing complete."
read -p "Press Enter to exit..."


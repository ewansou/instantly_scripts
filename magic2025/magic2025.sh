#!/bin/bash

# === CONFIGURABLE PARAMETERS ===
INPUT_FOLDER="./Source"
OUTPUT_FOLDER="./Output"
MOVED_FOLDER="./Moved"
BACKGROUND="./background.jpg"
OVERLAY="./overlay.png"
CHECK_INTERVAL_SECONDS=3
CONFIG_FILE="./placement_config.txt"

# === LOAD CONFIG FROM EXTERNAL FILE ===
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Configuration file '$CONFIG_FILE' not found."
  exit 1
fi

while IFS='=' read -r key value; do
  if [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ && -n "$value" ]]; then
    export "$key"="$value"
  fi
done < "$CONFIG_FILE"

# === DEFAULTS & FALLBACKS ===
: "${ENABLE_MOVE_TO_DISPLAY:=false}"
: "${DISPLAY_FOLDER:=./Display}"
: "${DISPLAY_DELAY_SECONDS:=2}"

# === PLACEMENT CONFIG VALIDATION ===
if [[ -z "$PLACEMENT_COUNT" ]]; then
  echo "❌ PLACEMENT_COUNT not defined in $CONFIG_FILE"
  exit 1
fi

for (( i=1; i<=PLACEMENT_COUNT; i++ )); do
  for var in WIDTH HEIGHT X Y; do
    value=$(eval echo "\$${var}${i}")
    if [[ -z "$value" ]]; then
      echo "❌ Missing configuration for ${var}${i} in $CONFIG_FILE"
      exit 1
    fi
  done
done

# === FILE VALIDATION ===
[ -f "$BACKGROUND" ] || { echo "❌ Background image '$BACKGROUND' not found."; exit 1; }
[ -f "$OVERLAY" ] || { echo "❌ Overlay image '$OVERLAY' not found."; exit 1; }

# === FOLDER SETUP ===
mkdir -p "$INPUT_FOLDER" "$OUTPUT_FOLDER" "$MOVED_FOLDER"

# === FUNCTION: In-memory multi-placement image compositing ===
place_image() {
  local input_image="$1"
  local output_image="$2"

  local cmd=(magick "$BACKGROUND")

  for (( i=1; i<=PLACEMENT_COUNT; i++ )); do
    WIDTH=$(eval echo "\$WIDTH$i")
    HEIGHT=$(eval echo "\$HEIGHT$i")
    X=$(eval echo "\$X$i")
    Y=$(eval echo "\$Y$i")

    echo "🔧 Placing image at slot $i: ${WIDTH}x${HEIGHT} at +${X}+${Y}"

    cmd+=(
      \( "$input_image" -auto-orient -resize "${WIDTH}x${HEIGHT}" \
      -gravity center -background none -extent "${WIDTH}x${HEIGHT}" \)
      -gravity NorthWest -geometry "+${X}+${Y}" -composite
    )
  done

  # Add overlay at top-left
  cmd+=("$OVERLAY" -gravity NorthWest -geometry "+0+0" -composite -flatten "$output_image")

  "${cmd[@]}"
}

# === MAIN LOOP ===
echo "📂 Watching Source folder at: $(realpath "$INPUT_FOLDER")"
echo "⏳ Monitoring $INPUT_FOLDER every $CHECK_INTERVAL_SECONDS seconds..."

while true; do
  find "$INPUT_FOLDER" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
    -o -iname "*.JPG" -o -iname "*.JPEG" -o -iname "*.PNG" \
  \) | while IFS= read -r FILE; do
    BASENAME=$(basename "$FILE" | sed 's/\.[^.]*$//')
    EXTENSION="${FILE##*.}"
    OUTPUT="$OUTPUT_FOLDER/${BASENAME}.jpg"
    DEST_MOVED="$MOVED_FOLDER/${BASENAME}.${EXTENSION}"

    if [ -f "$OUTPUT" ]; then
      echo "⚠️  Skipping: '$FILE'"
      echo "   ↪ A file with the same name already exists in '$OUTPUT_FOLDER': $(basename "$OUTPUT")"
      echo "   🧼 To reprocess it, delete the output file or rename the input."
      continue
    fi

    echo "🖼️  Processing $FILE → $OUTPUT"
    place_image "$FILE" "$OUTPUT"

    if [ $? -eq 0 ]; then
      mv "$FILE" "$DEST_MOVED"
      echo "📁 Moved original to $DEST_MOVED"

      if [[ "$ENABLE_MOVE_TO_DISPLAY" == "true" ]]; then
        mkdir -p "$DISPLAY_FOLDER"
        echo "⏳ Waiting $DISPLAY_DELAY_SECONDS seconds before moving to display..."
        sleep "$DISPLAY_DELAY_SECONDS"

        FINAL_DISPLAY_PATH="$DISPLAY_FOLDER/$(basename "$OUTPUT")"
        mv "$OUTPUT" "$FINAL_DISPLAY_PATH"
        echo "🖼️  Moved to display folder: $FINAL_DISPLAY_PATH"
      fi
    else
      echo "❌ Failed to process $FILE"
    fi
  done

  sleep "$CHECK_INTERVAL_SECONDS"
done
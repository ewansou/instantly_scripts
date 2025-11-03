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

# === NORMALIZE BOOLEAN VALUES ===
# Function to normalize boolean values (1/0, true/false) to true/false
normalize_bool() {
  local value="$1"
  # Convert to lowercase for comparison
  local lower_value=$(echo "$value" | tr '[:upper:]' '[:lower:]')
  case "$lower_value" in
    1|true|yes|on) echo "true" ;;
    0|false|no|off|"") echo "false" ;;
    *) echo "false" ;;
  esac
}

# Normalize all boolean configurations
ENABLE_MOVE_TO_DISPLAY=$(normalize_bool "$ENABLE_MOVE_TO_DISPLAY")
IMAGE_RENAME=$(normalize_bool "$IMAGE_RENAME")
VIDEO_RENAME=$(normalize_bool "$VIDEO_RENAME")
ENABLE_VIDEO_PROCESSING=$(normalize_bool "$ENABLE_VIDEO_PROCESSING")
VIDEO_INCLUDE_INPUT_AUDIO=$(normalize_bool "$VIDEO_INCLUDE_INPUT_AUDIO")

# Debug output (remove after testing)
echo "🔍 Debug: ENABLE_VIDEO_PROCESSING='$ENABLE_VIDEO_PROCESSING'"
echo "🔍 Debug: ENABLE_MOVE_TO_DISPLAY='$ENABLE_MOVE_TO_DISPLAY'"

# === DEFAULTS & FALLBACKS ===
: "${ENABLE_MOVE_TO_DISPLAY:=false}"
: "${DISPLAY_FOLDER:=./Display}"
: "${DISPLAY_DELAY_SECONDS:=2}"
: "${IMAGE_RENAME:=false}"
: "${IMAGE_RENAME_PREFIX:=}"
: "${VIDEO_RENAME:=false}"
: "${VIDEO_RENAME_PREFIX:=}"
: "${ENABLE_VIDEO_PROCESSING:=false}"
: "${VIDEO_WIDTH:=}"
: "${VIDEO_HEIGHT:=}"
: "${VIDEO_X:=0}"
: "${VIDEO_Y:=0}"
: "${VIDEO_INCLUDE_INPUT_AUDIO:=false}"
: "${IMAGE_OVERLAY_FILENAME:=$OVERLAY}"
: "${VIDEO_OVERLAY_FILENAME:=$OVERLAY}"

# Add ./ prefix if not already present
[[ "$IMAGE_OVERLAY_FILENAME" != /* && "$IMAGE_OVERLAY_FILENAME" != ./* ]] && IMAGE_OVERLAY_FILENAME="./$IMAGE_OVERLAY_FILENAME"
[[ "$VIDEO_OVERLAY_FILENAME" != /* && "$VIDEO_OVERLAY_FILENAME" != ./* ]] && VIDEO_OVERLAY_FILENAME="./$VIDEO_OVERLAY_FILENAME"

# === PLACEMENT CONFIG VALIDATION ===
if [[ -z "$PLACEMENT_COUNT" ]]; then
  echo "❌ PLACEMENT_COUNT not defined in $CONFIG_FILE"
  exit 1
fi

# === RENAME CONFIG VALIDATION ===
if [[ "$IMAGE_RENAME" == "true" && -z "$IMAGE_RENAME_PREFIX" ]]; then
  echo "❌ IMAGE_RENAME_PREFIX must be defined when IMAGE_RENAME=true in $CONFIG_FILE"
  exit 1
fi

if [[ "$VIDEO_RENAME" == "true" && -z "$VIDEO_RENAME_PREFIX" ]]; then
  echo "❌ VIDEO_RENAME_PREFIX must be defined when VIDEO_RENAME=true in $CONFIG_FILE"
  exit 1
fi

# === VIDEO CONFIG VALIDATION ===
if [[ "$ENABLE_VIDEO_PROCESSING" == "true" ]]; then
  if [[ -z "$VIDEO_WIDTH" || -z "$VIDEO_HEIGHT" ]]; then
    echo "❌ VIDEO_WIDTH and VIDEO_HEIGHT must be defined when ENABLE_VIDEO_PROCESSING=1 in $CONFIG_FILE"
    exit 1
  fi
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
# Check overlay files based on what processing is enabled
if [[ "$ENABLE_VIDEO_PROCESSING" == "true" ]]; then
  [ -f "$VIDEO_OVERLAY_FILENAME" ] || { echo "❌ Video overlay '$VIDEO_OVERLAY_FILENAME' not found."; exit 1; }
  # Only check image overlay if we might process images (not video-only mode)
  echo "🎬 Video processing mode enabled"
else
  # If video processing is disabled, we must have image overlay
  [ -f "$IMAGE_OVERLAY_FILENAME" ] || { echo "❌ Image overlay '$IMAGE_OVERLAY_FILENAME' not found."; exit 1; }
fi

# Check if background exists, if not we'll create a blank canvas
USE_BLANK_CANVAS=false
if [ ! -f "$BACKGROUND" ]; then
  echo "⚠️  Background image '$BACKGROUND' not found."
  echo "🎨 Creating blank canvas based on overlay dimensions..."
  USE_BLANK_CANVAS=true
  
  # Get overlay dimensions and color mode (using image overlay as reference)
  OVERLAY_INFO=$(magick identify -format "%wx%h %[colorspace]" "$IMAGE_OVERLAY_FILENAME")
  OVERLAY_DIMENSIONS=$(echo "$OVERLAY_INFO" | cut -d' ' -f1)
  OVERLAY_COLORSPACE=$(echo "$OVERLAY_INFO" | cut -d' ' -f2)
  
  echo "📏 Overlay dimensions: $OVERLAY_DIMENSIONS, Colorspace: $OVERLAY_COLORSPACE"
fi

# === FOLDER SETUP ===
mkdir -p "$INPUT_FOLDER" "$OUTPUT_FOLDER" "$MOVED_FOLDER"

# === FUNCTION: In-memory multi-placement image compositing ===
place_image() {
  local input_image="$1"
  local output_image="$2"

  local cmd=()
  
  # Start with either background image or blank canvas
  if [ "$USE_BLANK_CANVAS" = true ]; then
    cmd=(magick -size "$OVERLAY_DIMENSIONS" xc:white)
    # Convert to same colorspace as overlay
    if [[ "$OVERLAY_COLORSPACE" == "sRGB" ]]; then
      cmd+=(-colorspace sRGB)
    fi
  else
    cmd=(magick "$BACKGROUND")
  fi

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
  cmd+=("$IMAGE_OVERLAY_FILENAME" -gravity NorthWest -geometry "+0+0" -composite -flatten "$output_image")

  "${cmd[@]}"
}

# === FUNCTION: Video processing with ffmpeg ===
process_video() {
  local input_video="$1"
  local output_video="$2"
  
  # Get video overlay dimensions (take only first frame if multiple)
  local VIDEO_OVERLAY_INFO=$(magick identify -format "%wx%h\n" "$VIDEO_OVERLAY_FILENAME" 2>/dev/null | head -n1)
  local VIDEO_OVERLAY_DIMENSIONS="${VIDEO_OVERLAY_INFO%% *}"  # Take first dimension if multiple
  
  # Validate dimensions format
  if [[ ! "$VIDEO_OVERLAY_DIMENSIONS" =~ ^[0-9]+x[0-9]+$ ]]; then
    echo "❌ Invalid video overlay dimensions: $VIDEO_OVERLAY_DIMENSIONS"
    return 1
  fi
  
  # Create temporary file names
  local temp_resized="/tmp/magic2025_resized_$$_$(basename "$input_video")"
  local temp_on_bg="/tmp/magic2025_on_bg_$$_$(basename "$input_video")"
  
  # Ensure cleanup on exit
  trap "rm -f '$temp_resized' '$temp_on_bg'" EXIT
  
  echo "🎬 Step 1/3: Resizing video to ${VIDEO_WIDTH}x${VIDEO_HEIGHT}..."
  # Resize the video
  if ! ffmpeg -i "$input_video" -filter:v "scale=${VIDEO_WIDTH}:${VIDEO_HEIGHT}" -preset ultrafast -y "$temp_resized" 2>&1 | grep -E "(error|Error)" >&2; then
    :
  fi
  
  if [ ! -f "$temp_resized" ]; then
    echo "❌ Failed to resize video"
    rm -f "$temp_resized" "$temp_on_bg"
    return 1
  fi
  
  echo "🎬 Step 2/3: Placing video on background at position +${VIDEO_X}+${VIDEO_Y}..."
  # Place resized video on background
  if [ "$USE_BLANK_CANVAS" = true ]; then
    # Create blank canvas and place video
    echo "   Using blank canvas with dimensions: ${VIDEO_OVERLAY_DIMENSIONS}"
    if ! ffmpeg -f lavfi -i "color=c=white:s=${VIDEO_OVERLAY_DIMENSIONS}" -i "$temp_resized" \
      -filter_complex "[1]scale=${VIDEO_WIDTH}:${VIDEO_HEIGHT}[vid]; [0][vid]overlay=${VIDEO_X}:${VIDEO_Y}:shortest=1[out]" \
      -map "[out]" -preset ultrafast -y "$temp_on_bg" 2>&1 | grep -E "(error|Error)" >&2; then
      :
    fi
    
    if [ ! -f "$temp_on_bg" ]; then
      echo "❌ Failed to place video on blank canvas"
      echo "   Debug: VIDEO_OVERLAY_DIMENSIONS=${VIDEO_OVERLAY_DIMENSIONS}"
      echo "   Debug: VIDEO_WIDTH=${VIDEO_WIDTH}, VIDEO_HEIGHT=${VIDEO_HEIGHT}"
      echo "   Debug: VIDEO_X=${VIDEO_X}, VIDEO_Y=${VIDEO_Y}"
      rm -f "$temp_resized" "$temp_on_bg"
      return 1
    fi
  else
    # Use existing background
    if ! ffmpeg -loop 1 -i "$BACKGROUND" -i "$temp_resized" \
      -filter_complex "[1]scale=${VIDEO_WIDTH}:${VIDEO_HEIGHT}[vid]; [0][vid]overlay=${VIDEO_X}:${VIDEO_Y}:shortest=1[out]" \
      -map "[out]" -preset ultrafast -y "$temp_on_bg" 2>&1 | grep -E "(error|Error)" >&2; then
      :
    fi
    
    if [ ! -f "$temp_on_bg" ]; then
      echo "❌ Failed to place video on background"
      rm -f "$temp_resized" "$temp_on_bg"
      return 1
    fi
  fi
  
  echo "🎬 Step 3/3: Adding overlay..."
  # Add overlay on top and handle audio
  local audio_opts=""
  if [[ "$VIDEO_INCLUDE_INPUT_AUDIO" == "true" ]]; then
    audio_opts="-map 1:a? -c:a copy"
  fi
  
  if ! ffmpeg -loop 1 -i "$VIDEO_OVERLAY_FILENAME" -i "$temp_on_bg" \
    -filter_complex "[1]scale=${VIDEO_OVERLAY_DIMENSIONS}[vid]; [vid][0]overlay=0:0:shortest=1[out]" \
    -map "[out]" $audio_opts -preset ultrafast -y "$output_video" 2>&1 | grep -E "(error|Error)" >&2; then
    :
  fi
  
  if [ ! -f "$output_video" ]; then
    echo "❌ Failed to add overlay"
    rm -f "$temp_resized" "$temp_on_bg"
    return 1
  fi
  
  # Cleanup temp files
  rm -f "$temp_resized" "$temp_on_bg"
  
  echo "✅ Video processing completed successfully"
  return 0
}

# === MAIN LOOP ===
echo "📂 Watching Source folder at: $(realpath "$INPUT_FOLDER")"
echo "⏳ Monitoring $INPUT_FOLDER every $CHECK_INTERVAL_SECONDS seconds..."

if [[ "$ENABLE_VIDEO_PROCESSING" == "true" ]]; then
  echo "🎬 Video processing enabled (MP4 files)"
  echo "   Video size: ${VIDEO_WIDTH}x${VIDEO_HEIGHT} at position +${VIDEO_X}+${VIDEO_Y}"
  echo "   Audio: $([[ "$VIDEO_INCLUDE_INPUT_AUDIO" == "true" ]] && echo "Preserved" || echo "Removed")"
fi

# Initialize rename counters
IMAGE_RENAME_COUNTER=1
VIDEO_RENAME_COUNTER=1

while true; do
  if [[ "$IMAGE_RENAME" == "true" || "$VIDEO_RENAME" == "true" ]]; then
    # Create temporary file list sorted in ascending order
    TEMP_FILE_LIST=$(mktemp)
    
    # Build find pattern based on enabled features
    FIND_PATTERN="-type f \("
    FIND_PATTERN="$FIND_PATTERN -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png'"
    FIND_PATTERN="$FIND_PATTERN -o -iname '*.JPG' -o -iname '*.JPEG' -o -iname '*.PNG'"
    
    if [[ "$ENABLE_VIDEO_PROCESSING" == "true" ]]; then
      FIND_PATTERN="$FIND_PATTERN -o -iname '*.mp4' -o -iname '*.MP4'"
    fi
    FIND_PATTERN="$FIND_PATTERN \)"
    
    eval "find '$INPUT_FOLDER' $FIND_PATTERN" | sort > "$TEMP_FILE_LIST"

    while IFS= read -r FILE; do
      [[ -z "$FILE" ]] && continue  # Skip empty lines

      # Check file type and determine rename settings
      EXTENSION="${FILE##*.}"
      EXTENSION_LOWER=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')
      
      # Determine rename settings based on file type
      if [[ "$EXTENSION_LOWER" == "mp4" && "$VIDEO_RENAME" == "true" ]]; then
        NEW_FILENAME="${VIDEO_RENAME_PREFIX}-$(printf "%04d" $VIDEO_RENAME_COUNTER).${EXTENSION}"
        SHOULD_RENAME=true
        COUNTER_VAR="VIDEO_RENAME_COUNTER"
      elif [[ "$EXTENSION_LOWER" =~ ^(jpg|jpeg|png)$ && "$IMAGE_RENAME" == "true" ]]; then
        NEW_FILENAME="${IMAGE_RENAME_PREFIX}-$(printf "%04d" $IMAGE_RENAME_COUNTER).${EXTENSION}"
        SHOULD_RENAME=true
        COUNTER_VAR="IMAGE_RENAME_COUNTER"
      else
        SHOULD_RENAME=false
      fi

      # Rename the file if applicable
      if [[ "$SHOULD_RENAME" == true ]]; then
        NEW_FILE_PATH="$INPUT_FOLDER/$NEW_FILENAME"
        if mv "$FILE" "$NEW_FILE_PATH" 2>/dev/null; then
          echo "🔄 Renamed: $(basename "$FILE") → $NEW_FILENAME"
          CURRENT_FILE="$NEW_FILE_PATH"
          if [[ "$COUNTER_VAR" == "VIDEO_RENAME_COUNTER" ]]; then
            ((VIDEO_RENAME_COUNTER++))
          else
            ((IMAGE_RENAME_COUNTER++))
          fi
        else
          echo "⚠️  Failed to rename: $FILE"
          CURRENT_FILE="$FILE"
        fi
      else
        CURRENT_FILE="$FILE"
      fi

      # Process the file (renamed or original)
      BASENAME=$(basename "$CURRENT_FILE" | sed 's/\.[^.]*$//')
      EXTENSION="${CURRENT_FILE##*.}"
      EXTENSION_LOWER=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')
      
      # Determine if this is a video or image
      if [[ "$ENABLE_VIDEO_PROCESSING" == "true" && "$EXTENSION_LOWER" == "mp4" ]]; then
        OUTPUT="$OUTPUT_FOLDER/${BASENAME}.mp4"
      else
        OUTPUT="$OUTPUT_FOLDER/${BASENAME}.jpg"
      fi
      
      DEST_MOVED="$MOVED_FOLDER/${BASENAME}.${EXTENSION}"

      if [ -f "$OUTPUT" ]; then
        echo "⚠️  Skipping: '$CURRENT_FILE'"
        echo "   ↪ A file with the same name already exists in '$OUTPUT_FOLDER': $(basename "$OUTPUT")"
        echo "   🧼 To reprocess it, delete the output file or rename the input."
        continue
      fi

      # Process based on file type
      if [[ "$ENABLE_VIDEO_PROCESSING" == "true" && "$EXTENSION_LOWER" == "mp4" ]]; then
        echo "🎬 Processing video $CURRENT_FILE → $OUTPUT"
        process_video "$CURRENT_FILE" "$OUTPUT"
      else
        echo "🖼️  Processing image $CURRENT_FILE → $OUTPUT"
        # Check if image overlay exists before processing
        if [ ! -f "$IMAGE_OVERLAY_FILENAME" ]; then
          echo "❌ Cannot process image: Image overlay '$IMAGE_OVERLAY_FILENAME' not found"
          echo "   💡 Enable video processing mode if you only want to process videos"
          continue
        fi
        place_image "$CURRENT_FILE" "$OUTPUT"
      fi

      if [ $? -eq 0 ]; then
        mv "$CURRENT_FILE" "$DEST_MOVED"
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
        echo "❌ Failed to process $CURRENT_FILE"
      fi
    done < "$TEMP_FILE_LIST"

    # Clean up temporary file
    rm -f "$TEMP_FILE_LIST"
  else
    # Original processing without renaming
    # Build find pattern based on enabled features
    FIND_PATTERN="-type f \("
    FIND_PATTERN="$FIND_PATTERN -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png'"
    FIND_PATTERN="$FIND_PATTERN -o -iname '*.JPG' -o -iname '*.JPEG' -o -iname '*.PNG'"
    
    if [[ "$ENABLE_VIDEO_PROCESSING" == "true" ]]; then
      FIND_PATTERN="$FIND_PATTERN -o -iname '*.mp4' -o -iname '*.MP4'"
    fi
    FIND_PATTERN="$FIND_PATTERN \)"
    
    eval "find '$INPUT_FOLDER' $FIND_PATTERN" | while IFS= read -r FILE; do
      CURRENT_FILE="$FILE"

      BASENAME=$(basename "$CURRENT_FILE" | sed 's/\.[^.]*$//')
      EXTENSION="${CURRENT_FILE##*.}"
      EXTENSION_LOWER=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')
      
      # Determine if this is a video or image
      if [[ "$ENABLE_VIDEO_PROCESSING" == "true" && "$EXTENSION_LOWER" == "mp4" ]]; then
        OUTPUT="$OUTPUT_FOLDER/${BASENAME}.mp4"
      else
        OUTPUT="$OUTPUT_FOLDER/${BASENAME}.jpg"
      fi
      
      DEST_MOVED="$MOVED_FOLDER/${BASENAME}.${EXTENSION}"

      if [ -f "$OUTPUT" ]; then
        echo "⚠️  Skipping: '$FILE'"
        echo "   ↪ A file with the same name already exists in '$OUTPUT_FOLDER': $(basename "$OUTPUT")"
        echo "   🧼 To reprocess it, delete the output file or rename the input."
        continue
      fi

      # Process based on file type
      if [[ "$ENABLE_VIDEO_PROCESSING" == "true" && "$EXTENSION_LOWER" == "mp4" ]]; then
        echo "🎬 Processing video $CURRENT_FILE → $OUTPUT"
        process_video "$CURRENT_FILE" "$OUTPUT"
      else
        echo "🖼️  Processing image $CURRENT_FILE → $OUTPUT"
        # Check if image overlay exists before processing
        if [ ! -f "$IMAGE_OVERLAY_FILENAME" ]; then
          echo "❌ Cannot process image: Image overlay '$IMAGE_OVERLAY_FILENAME' not found"
          echo "   💡 Enable video processing mode if you only want to process videos"
          continue
        fi
        place_image "$CURRENT_FILE" "$OUTPUT"
      fi

      if [ $? -eq 0 ]; then
        mv "$CURRENT_FILE" "$DEST_MOVED"
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
        echo "❌ Failed to process $CURRENT_FILE"
      fi
    done
  fi

  sleep "$CHECK_INTERVAL_SECONDS"
done
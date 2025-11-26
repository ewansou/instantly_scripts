================================================================================
                            MAGIC2025 - Media Processing Script
================================================================================

OVERVIEW
--------
Magic2025 is an automated media processing script that monitors a folder and
processes images and videos by:
- Cropping to specific regions
- Rotating images/videos
- Placing them on backgrounds (or blank canvases)
- Adding overlay graphics
- Optionally renaming files with sequential numbering
- Moving processed files to output/display folders

QUICK START
-----------
1. Place your media files in the ./Source folder
2. Configure placement_config.txt with your settings
3. Run: ./magic2025.sh
4. Processed files appear in ./Output folder
5. Original files are moved to ./Moved folder

FOLDER STRUCTURE
----------------
./Source/         - Place your input files here (monitored folder)
./Output/         - Processed files appear here
./Moved/          - Original files moved here after processing
./Display/        - Optional final destination (if enabled)

SUPPORTED FILE FORMATS
----------------------
Images: JPG, JPEG, PNG (case-insensitive)
Videos: MP4 (when video processing is enabled)

CONFIGURATION FILE: placement_config.txt
========================================

GENERAL SETTINGS
----------------
ENABLE_MOVE_TO_DISPLAY    - Move files to Display folder after processing (true/false)
DISPLAY_FOLDER            - Path to display folder (default: ./Display)
DISPLAY_DELAY_SECONDS     - Delay before moving to display folder (default: 2)

IMAGE PROCESSING SETTINGS
-------------------------
IMAGE_BACKGROUND_FILENAME - Background image for photos (optional, creates white canvas if empty)
IMAGE_OVERLAY_FILENAME    - Overlay image to add on top (required for image processing)
IMAGE_RENAME              - Enable sequential renaming (true/false)
IMAGE_RENAME_PREFIX       - Prefix for renamed files (e.g., "Photo")
IMAGE_ROTATION            - Rotation angle: 0, 90, 180, or 270 degrees

IMAGE CROPPING (optional)
IMAGE_CROP_WIDTH          - Width of crop area (leave empty to disable)
IMAGE_CROP_HEIGHT         - Height of crop area (leave empty to disable)
IMAGE_CROP_X              - X position of crop area (default: 0)
IMAGE_CROP_Y              - Y position of crop area (default: 0)

IMAGE PLACEMENTS
PLACEMENT_COUNT           - Number of positions to place the image (1-4 or more)
For each placement N (where N = 1, 2, 3...):
  XN                      - X position on background
  YN                      - Y position on background
  WIDTHN                  - Width to resize image
  HEIGHTN                 - Height to resize image

VIDEO PROCESSING SETTINGS
-------------------------
ENABLE_VIDEO_PROCESSING   - Enable MP4 video processing (true/false)
VIDEO_BACKGROUND_FILENAME - Background image for videos (optional, creates white canvas if empty)
VIDEO_OVERLAY_FILENAME    - Overlay image for videos (required for video processing)
VIDEO_RENAME              - Enable sequential renaming (true/false)
VIDEO_RENAME_PREFIX       - Prefix for renamed video files
VIDEO_ROTATION            - Rotation angle: 0, 90, 180, or 270 degrees
VIDEO_INCLUDE_INPUT_AUDIO - Preserve original audio (true/false)

VIDEO CROPPING (optional)
VIDEO_CROP_WIDTH          - Width of crop area (leave empty to disable)
VIDEO_CROP_HEIGHT         - Height of crop area (leave empty to disable)
VIDEO_CROP_X              - X position of crop area (default: 0)
VIDEO_CROP_Y              - Y position of crop area (default: 0)

VIDEO PLACEMENT (single position only)
VIDEO_X                   - X position on background
VIDEO_Y                   - Y position on background
VIDEO_WIDTH               - Width to resize video
VIDEO_HEIGHT              - Height to resize video

CONFIGURATION EXAMPLES
======================

Example 1: Basic Image Processing
---------------------------------
IMAGE_BACKGROUND_FILENAME=background.jpg
IMAGE_OVERLAY_FILENAME=overlay.png
IMAGE_RENAME=false
IMAGE_ROTATION=0
PLACEMENT_COUNT=1
X1=100
Y1=100
WIDTH1=800
HEIGHT1=600

Example 2: Image with Cropping and Rotation
--------------------------------------------
IMAGE_BACKGROUND_FILENAME=
IMAGE_OVERLAY_FILENAME=frame.png
IMAGE_CROP_WIDTH=500
IMAGE_CROP_HEIGHT=500
IMAGE_CROP_X=100
IMAGE_CROP_Y=50
IMAGE_ROTATION=90
PLACEMENT_COUNT=1
X1=0
Y1=0
WIDTH1=400
HEIGHT1=400

Example 3: Multiple Image Placements
------------------------------------
IMAGE_BACKGROUND_FILENAME=collage-bg.jpg
IMAGE_OVERLAY_FILENAME=collage-overlay.png
PLACEMENT_COUNT=4
X1=0
Y1=0
WIDTH1=400
HEIGHT1=300
X2=420
Y2=0
WIDTH2=400
HEIGHT2=300
X3=0
Y3=320
WIDTH3=400
HEIGHT3=300
X4=420
Y4=320
WIDTH4=400
HEIGHT4=300

Example 4: Video Processing with Cropping
-----------------------------------------
ENABLE_VIDEO_PROCESSING=true
VIDEO_BACKGROUND_FILENAME=
VIDEO_OVERLAY_FILENAME=video-frame.png
VIDEO_CROP_WIDTH=1080
VIDEO_CROP_HEIGHT=1080
VIDEO_CROP_X=420
VIDEO_CROP_Y=0
VIDEO_ROTATION=0
VIDEO_X=50
VIDEO_Y=50
VIDEO_WIDTH=720
VIDEO_HEIGHT=720

PROCESSING WORKFLOW
===================

For Images:
1. Auto-orient the image
2. Crop (if enabled) - extracts specified region
3. Rotate (if enabled) - rotates the cropped region
4. Resize to fit each placement slot
5. Place on background (or white canvas)
6. Add overlay on top
7. Save to Output folder

For Videos:
1. Crop (if enabled) - extracts specified region
2. Rotate (if enabled) - rotates the cropped region
3. Scale to VIDEO_WIDTH x VIDEO_HEIGHT
4. Place on background (or white canvas) at VIDEO_X, VIDEO_Y
5. Add video overlay on top
6. Preserve/remove audio based on settings
7. Save to Output folder

TIPS AND BEST PRACTICES
=======================

1. Backgrounds are Optional
   - Leave IMAGE_BACKGROUND_FILENAME or VIDEO_BACKGROUND_FILENAME empty
   - Script creates white canvas matching overlay dimensions

2. Cropping
   - Both WIDTH and HEIGHT must be specified to enable cropping
   - Leave both empty to disable cropping
   - Crop happens BEFORE rotation

3. File Naming
   - Enable IMAGE_RENAME or VIDEO_RENAME for sequential numbering
   - Original extensions are preserved
   - Example: IMAGE_RENAME_PREFIX=Photo → Photo-0001.jpg, Photo-0002.png

4. Performance
   - Script checks every 3 seconds for new files
   - Skips files that already exist in Output folder
   - Process files in batches for better performance

5. Boolean Values
   - Accepts: true/false, yes/no, on/off, 1/0
   - All normalized to true/false internally

TROUBLESHOOTING
===============

"Configuration file not found"
- Ensure placement_config.txt exists in script directory

"Overlay not found"
- Overlay files are required for processing
- Check IMAGE_OVERLAY_FILENAME and VIDEO_OVERLAY_FILENAME paths

"Invalid rotation value"
- Use only: 0, 90, 180, or 270

"Both WIDTH and HEIGHT must be specified for cropping"
- Either specify both dimensions or leave both empty

Files not processing
- Check file extensions (.jpg, .jpeg, .png, .mp4)
- Ensure output file doesn't already exist
- Check script has read/write permissions

REQUIREMENTS
============
- bash
- ImageMagick (magick command)
- FFmpeg (for video processing)

================================================================================
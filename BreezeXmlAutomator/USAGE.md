# XML Automator Usage Guide

## Overview
This script creates multiple XML files from a base template, updating specific values for each group as defined in `config.txt`.

## Features
- **Multi-file support**: Create multiple XML files in one run
- **XML path notation**: Update values using paths like `photobooth_settings/photoPostprocessURL`
- **Flexible configuration**: Each group can have different numbers of updates
- **Cross-platform**: Works on macOS, Linux, and Windows (Git Bash)

## Requirements
- Bash shell
- Perl (pre-installed on most systems)

## Usage

### 1. Set up your configuration
Edit `config.txt` to define your groups and the values to update.

### 2. Run the script
```bash
./xml_automator.sh
```

## Configuration Format

Groups use numeric format (01, 02, 03, etc.) and are automatically detected by the script.

### Example Configuration

```bash
# GROUP 01
01_BASE_XML=/path/to/template.xml
01_NEW_XML_NAME=output-file-1.xml
01_NEW_XML_OUTPUT_DIR=/path/to/output/directory1

# XML updates for this group
01_XML_PATHS[0]=photobooth_settings/photoPostprocessURL
01_XML_VALUES[0]=https://api.example.com/endpoint1

01_XML_PATHS[1]=photobooth_settings/photoboothImageDir
01_XML_VALUES[1]=C:\Images\Event1

# GROUP 02
02_BASE_XML=/path/to/template.xml
02_NEW_XML_NAME=output-file-2.xml
02_NEW_XML_OUTPUT_DIR=/path/to/output/directory2

# Only one update for this group
02_XML_PATHS[0]=photobooth_settings/photoPostprocessURL
02_XML_VALUES[0]=https://api.example.com/endpoint2
```

### Configuration Variables

For each group (NN = 01, 02, 03, etc.):

- `NN_BASE_XML` - Path to the source XML file
- `NN_NEW_XML_NAME` - Name for the output XML file
- `NN_NEW_XML_OUTPUT_DIR` - Directory where the output file will be saved
- `NN_XML_PATHS[i]` - XML path to update (supports nested paths with `/`)
- `NN_XML_VALUES[i]` - New value to set

## XML Path Notation

- **Simple tag**: `tagname`
- **Nested tag**: `parent/tagname`
- **Example**: `photobooth_settings/photoPostprocessURL`

## Output

The script will:
1. Process all groups found in config.txt
2. Copy the base XML file to the output directory
3. Update specified XML values
4. Show progress for each group
5. Display a summary at the end

### Example Output
```
XML Automator - Multi-File Processing
=====================================
Processing groups: 01 02 03 04 05 06 07 08 09 10

================================================================
Processing Group: 01
================================================================
  Step 1: Copying XML file...
  Successfully copied to /output/path/file.xml
  Step 2: Updating XML values...
    Updated: photobooth_settings/photoPostprocessURL = https://new-url.com
  Group 01 processing completed!
  Output file: /output/path/file.xml

================================================================
Processing Summary:
  Successful: 10 group(s)
  Failed: 0 group(s)
  Skipped: 0 group(s)
================================================================
```

## Tips

- Groups must use two-digit numeric format: 01, 02, 03, etc.
- The script automatically detects and processes all groups defined in config.txt
- You can skip groups (e.g., have 01, 02, 05 without 03 and 04)
- Paths with backslashes (Windows-style) are handled correctly
- No quotes needed in config.txt unless values contain spaces
- Create output directories are created automatically if they don't exist
- Test with one group first before adding more

## Troubleshooting

**Script not finding groups**: Ensure your groups use two-digit format (01, not 1)

**XML values not updating**: Check that the XML path matches exactly what's in your XML file

**File not found errors**: Use absolute paths in config.txt for BASE_XML

**Permission denied**: Make sure the script is executable: `chmod +x xml_automator.sh`
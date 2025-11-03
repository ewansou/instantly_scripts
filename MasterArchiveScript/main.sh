#!/bin/bash

# Load configuration from config.txt
CONFIG_FILE="$(dirname "$0")/config.txt"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file $CONFIG_FILE not found!"
    exit 1
fi

# No global variables needed - will use temp files for everything

# Function to parse config file and create temporary files for processing
parse_config() {
    # Clean up any existing temp files
    rm -f /tmp/pb_groups_*.txt /tmp/pb_delete_folders.txt /tmp/pb_variables.txt 2>/dev/null
    
    local group_index=0
    local current_source=""
    local current_file_type=""
    local current_dest=""
    
    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
        
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        case "$key" in
            "SOURCE_FOLDER")
                # Save previous group if complete
                if [[ -n "$current_source" && -n "$current_file_type" && -n "$current_dest" ]]; then
                    echo "$current_source|$current_file_type|$current_dest" >> "/tmp/pb_groups_${group_index}.txt"
                    ((group_index++))
                fi
                current_source="$value"
                current_file_type=""
                current_dest=""
                ;;
            "FILE_TYPE")
                current_file_type="$value"
                ;;
            "DESTINATION_FOLDER")
                current_dest="$value"
                ;;
            "DELETE_EMPTY_FOLDER")
                # Save folder to check for deletion
                echo "$value" >> "/tmp/pb_delete_folders.txt"
                ;;
            *)
                # Any other key is treated as a variable definition
                echo "$key=$value" >> "/tmp/pb_variables.txt"
                ;;
        esac
    done < "$CONFIG_FILE"
    
    # Save the last group
    if [[ -n "$current_source" && -n "$current_file_type" && -n "$current_dest" ]]; then
        echo "$current_source|$current_file_type|$current_dest" >> "/tmp/pb_groups_${group_index}.txt"
    fi
}

# Function to substitute variables
substitute_vars() {
    local text="$1"
    local date_folder="$2"
    local event_id="$3"
    
    # Replace date and event ID
    text="${text//DDMMYYYY_eventId/${date_folder}_${event_id}}"
    
    # Replace all variables from config file
    if [[ -f "/tmp/pb_variables.txt" ]]; then
        while IFS='=' read -r var_name var_value; do
            [[ -z "$var_name" ]] && continue
            text="${text//$var_name/$var_value}"
        done < "/tmp/pb_variables.txt"
    fi
    
    echo "$text"
}

# Function to move files by extension from a directory (case-insensitive)
move_files_by_extension() {
    local source_path="$1"
    local dest_path="$2"
    local file_ext="$3"
    
    local files_moved=0
    local moved_files=()
    
    # Find all files in source directory
    if [[ -d "$source_path" ]]; then
        # Use find with case-insensitive matching
        while IFS= read -r -d '' file; do
            if [[ -f "$file" ]]; then
                local filename=$(basename "$file")
                local file_extension="${filename##*.}"
                
                # Compare extensions case-insensitively
                if [[ "$(echo "$file_extension" | tr '[:upper:]' '[:lower:]')" == "$(echo "$file_ext" | tr '[:upper:]' '[:lower:]')" ]]; then
                    mv "$file" "$dest_path/" && {
                        moved_files+=("$filename")
                        ((files_moved++))
                    }
                fi
            fi
        done < <(find "$source_path" -maxdepth 1 -type f -print0 2>/dev/null)
    fi
    
    # Report results
    if [[ $files_moved -gt 0 ]]; then
        echo "     → Successfully moved $files_moved file(s): ${moved_files[*]}"
    else
        echo "     → No $file_ext files found to move"
    fi
}

# Function to move a single file
move_single_file() {
    local source_file="$1"
    local dest_path="$2"
    local expected_ext="$3"
    
    if [[ -f "$source_file" ]]; then
        local filename=$(basename "$source_file")
        local file_extension="${filename##*.}"
        
        # Check if file extension matches (case-insensitive)
        if [[ "$(echo "$file_extension" | tr '[:upper:]' '[:lower:]')" == "$(echo "$expected_ext" | tr '[:upper:]' '[:lower:]')" ]]; then
            mv "$source_file" "$dest_path/" && {
                echo "     → Successfully moved file: $filename"
                return 0
            }
        else
            echo "     ⚠️  File extension mismatch: expected .$expected_ext, found .$file_extension"
            return 1
        fi
    else
        echo "     ⚠️  Source file not found: $source_file"
        return 1
    fi
}

# Function to safely delete specified empty folders
delete_empty_folders() {
    local folders_deleted=0
    local folders_warned=0
    
    # Check if delete folders file exists
    if [[ -f "/tmp/pb_delete_folders.txt" ]]; then
        echo
        echo "🗑️  Checking specified folders for deletion..."
        
        while IFS= read -r folder_raw; do
            [[ -z "$folder_raw" ]] && continue
            
            # Substitute variables in folder path
            local folder_path=$(substitute_vars "$folder_raw" "$date" "$eventId")
            
            if [[ -d "$folder_path" ]]; then
                # Check if folder is completely empty (no files or subdirectories)
                if [[ -z "$(ls -A "$folder_path" 2>/dev/null)" ]]; then
                    rmdir "$folder_path" 2>/dev/null && {
                        echo "     ✅ Deleted empty folder: $folder_path"
                        ((folders_deleted++))
                    }
                else
                    echo "     ⚠️  WARNING: Folder is NOT empty, skipping deletion: $folder_path"
                    ((folders_warned++))
                fi
            else
                echo "     ❌ Folder not found: $folder_path"
            fi
        done < "/tmp/pb_delete_folders.txt"
        
        echo
        if [[ $folders_deleted -gt 0 ]]; then
            echo "     📊 Summary: Deleted $folders_deleted empty folder(s)"
        fi
        if [[ $folders_warned -gt 0 ]]; then
            echo "     ⚠️  Summary: $folders_warned folder(s) were NOT empty and were preserved"
        fi
        if [[ $folders_deleted -eq 0 && $folders_warned -eq 0 ]]; then
            echo "     📁 No folders were processed for deletion"
        fi
    fi
}

day=$(date +"%d")
month=$(date +"%m")
year=$(date +"%Y")
date="$day""$month""$year"

while true

do
	echo
	echo "📋 PHOTOBOOTH ARCHIVE TOOL"
	echo "═══════════════════════════════"
	echo
	echo "⚠️  IMPORTANT: Before proceeding, please CLOSE any relevant programs:"
	echo "   📷 Breeze DSLR Remote Pro"
	echo "   🖼️ Selection"
	echo "   💻 Any photo editing software"
	echo "   📁 File explorer windows showing event folders"
	echo "   ⚠️ Only this window (running this script) should be on"
	echo
	echo "   Press ENTER when all programs are closed..."
	read -p $''
	echo
	echo "🔸 STEP 1: Enter your Event ID"
	echo "   📅 Get Event ID from our calendar. It is the word AFTER the closing square bracket."
	echo "   📝 Type in exact, it is case sensitive. ❌ DO NOT COPY AND PASTE."
	echo "   📝 For example, if you see [PB] knoxxICA. Then key in knoxxICA."
	echo "   📝 For multi-day events: do NOT include dates or any prefix/postfix. Enter the Event ID as per calendar"
	echo "   💡 Example: 'knoxxICA' (not 'knoxxICDay1')"
	echo
	read -e -p $'' eventId
	eventId=$(echo "$eventId" | xargs)

	if [[ -z "$eventId" ]]; then
		echo
		echo "❌ Error: Event ID cannot be empty!"
		echo "   Please try again."
		echo
		continue
	else
		echo
		echo "📝 Event ID entered: $eventId"
		echo
		echo "🔸 STEP 2: Confirm Event ID"
		echo "⚠️  Ensure that the Event ID shown above matches exactly the Event ID in our calendar"
		echo "⚠️  WARNING: Incorrect Event ID may result in penalties!"
		echo
		echo "   Type 'y' if correct, 'n' to re-enter:"
		read -p $'' confirm

		case $confirm in
			y|Y) 
			echo
			echo "🚀 Starting archive process..."
			echo

			# Parse configuration now (only when needed)
			parse_config

			photoboothnewFolderName="$date"_"${eventId}"
			
			# Process each group from configuration
			echo
			echo "🗂️  Starting file archiving for event: $eventId"
			echo "📅 Date: $date"
			echo "═══════════════════════════════════════════════════"
			
			# Process each group file
			for group_file in /tmp/pb_groups_*.txt; do
				[[ ! -f "$group_file" ]] && continue
				
				while IFS='|' read -r source_raw file_type dest_raw; do
					# Skip if any component is missing
					[[ -z "$source_raw" || -z "$file_type" || -z "$dest_raw" ]] && continue
					
					# Substitute variables
					source_path=$(substitute_vars "$source_raw" "$date" "$eventId")
					dest_path=$(substitute_vars "$dest_raw" "$date" "$eventId")
					
					sleep 1
					echo
					echo "📁 Processing: $file_type files"
					echo "   From: $source_path"
					echo "   To:   $dest_path"
					
					# Create destination directory
					mkdir -p "$dest_path"
					
					# Move files by extension or single file
					if [[ -d "$source_path" ]]; then
						# Source is a directory - move files by extension
						move_files_by_extension "$source_path" "$dest_path" "$file_type"
					elif [[ -f "$source_path" ]]; then
						# Source is a single file - move the file
						move_single_file "$source_path" "$dest_path" "$file_type"
					else
						echo "     ⚠️  Source not found: $source_path"
					fi
				done < "$group_file"
			done
			
			# Delete empty folders
			delete_empty_folders
			
			# Clean up temp files
			rm -f /tmp/pb_groups_*.txt /tmp/pb_delete_folders.txt /tmp/pb_variables.txt 2>/dev/null

			echo
			echo "═══════════════════════════════════════════════════"
			echo "✅ Archiving completed successfully!"
			echo "💡 Note: If you made a mistake with the Event ID, please notify your supervisor"
			echo "⚠️  IMPORTANT: Ensure Dropbox sync completes before turning off computer"
			echo "   (Check Dropbox icon in system tray)"
			echo
			echo "⏱️  Exiting in 5 seconds..."
			for i in 5 4 3 2 1; do
				echo "   $i..."
				sleep 1
			done
			exit
			;;

			n|N) 
			echo
			echo "🔄 Please enter Event ID again"
			echo
			continue 
			;;
			*) 
			echo
			echo "❓ Invalid input. Please type 'y' or 'n'"
			echo
			;;
		esac
	fi
done

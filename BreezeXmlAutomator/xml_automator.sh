#!/bin/bash

# XML Automator Script - Final Simple Version

# Auto-detect all groups from config file
GROUP_LIST=$(grep -E "^[0-9]{2}_BASE_XML=" config.txt | cut -d'_' -f1 | sort -u | tr '\n' ' ')

# Check if config file exists
if [ ! -f "config.txt" ]; then
    echo "Error: config.txt file not found!"
    exit 1
fi

# Function to get variable value from config file
get_config_value() {
    local var_name="$1"
    grep "^${var_name}=" config.txt | head -1 | cut -d'=' -f2-
}

# Function to process a single group
process_group() {
    local group_name="$1"
    
    echo ""
    echo "================================================================"
    echo "Processing Group: ${group_name}"
    echo "================================================================"
    
    # Get group-specific variables
    local base_xml=$(get_config_value "${group_name}_BASE_XML")
    local new_xml=$(get_config_value "${group_name}_NEW_XML_NAME")
    local output_dir=$(get_config_value "${group_name}_NEW_XML_OUTPUT_DIR")
    
    # Skip if group not defined
    if [ -z "$base_xml" ]; then
        echo "  Group ${group_name} not defined in config.txt, skipping..."
        return 0
    fi
    
    # Validate required variables for this group
    if [ -z "$new_xml" ] || [ -z "$output_dir" ]; then
        echo "Error: Missing required configuration for group ${group_name}!"
        return 1
    fi
    
    # Check if base XML file exists
    if [ ! -f "$base_xml" ]; then
        echo "Error: Base XML file '$base_xml' not found for group ${group_name}!"
        return 1
    fi
    
    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"
    
    # Step 1: Copy the base XML file
    echo "  Step 1: Copying XML file..."
    cp "$base_xml" "$output_dir/$new_xml"
    
    if [ $? -ne 0 ]; then
        echo "  Error: Failed to copy XML file!"
        return 1
    fi
    
    echo "  Successfully copied to $output_dir/$new_xml"
    
    # Step 2: Process XML updates
    echo "  Step 2: Updating XML values..."
    
    # Path to the new XML file
    local new_xml_path="$output_dir/$new_xml"
    
    # Process updates
    local i=0
    local found_updates=false
    
    while true; do
        local path=$(get_config_value "${group_name}_XML_PATHS\[${i}\]")
        local value=$(get_config_value "${group_name}_XML_VALUES\[${i}\]")
        
        if [ -z "$path" ]; then
            break
        fi
        
        found_updates=true
        if [ ! -z "$value" ]; then
            # Simple direct perl replacement
            if [[ "$path" == *"/"* ]]; then
                # Handle path like photobooth_settings/photoPostprocessURL
                IFS='/' read -r parent tag <<< "$path"
                perl -i -pe "
                    if (/<${parent}>/) {
                        \$in_parent = 1;
                    }
                    if (\$in_parent && /<${tag}>.*<\/${tag}>/) {
                        s|<${tag}>.*<\/${tag}>|<${tag}>${value}<\/${tag}>|;
                        \$found = 1;
                    }
                    if (/<\/${parent}>/) {
                        \$in_parent = 0;
                    }
                " "$new_xml_path"
            else
                # Simple tag replacement
                perl -i -pe "s|<${path}>.*</${path}>|<${path}>${value}</${path}>|" "$new_xml_path"
            fi
            echo "    Updated: ${path} = ${value}"
        fi
        ((i++))
    done
    
    if [ "$found_updates" = false ]; then
        echo "  No XML paths defined for group ${group_name}, skipping updates."
    fi
    
    echo "  Group ${group_name} processing completed!"
    echo "  Output file: $new_xml_path"
}

# Main script execution
echo "XML Automator - Multi-File Processing"
echo "====================================="

echo "Processing groups: $GROUP_LIST"

# Process each group
success_count=0
error_count=0
skipped_count=0

for group in $GROUP_LIST; do
    # Check if group exists in config
    if grep -q "^${group}_BASE_XML=" config.txt; then
        if process_group "$group"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    else
        ((skipped_count++))
        echo ""
        echo "Group ${group} not found in config.txt, skipping..."
    fi
done

# Summary
echo ""
echo "================================================================"
echo "Processing Summary:"
echo "  Successful: ${success_count} group(s)"
echo "  Failed: ${error_count} group(s)"
echo "  Skipped: ${skipped_count} group(s)"
echo "================================================================"

# Exit with appropriate code
if [ $error_count -eq 0 ]; then
    echo "All defined groups processed successfully!"
    exit 0
else
    echo "Some groups failed to process."
    exit 1
fi
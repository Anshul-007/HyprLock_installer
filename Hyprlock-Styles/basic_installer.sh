#!/bin/bash
# Define base directories for styles and fonts
STYLE_BASE_DIR="$HOME/.config/Hyprlock-Styles"
CONFIG_DIR="$HOME/.config/hypr"
SUPER_FONT_DIR="$STYLE_BASE_DIR/FONT_DIR"
INSTALLED_FONTS_FILE="$SUPER_FONT_DIR/installed_fonts.txt"
LAST_STYLE_FILE="$CONFIG_DIR/last_applied_style.txt"
# Define the rsync exclusion file
EXCLUDE_FILE="/tmp/exclude_files.txt"
# Define files to exclude from deletion
EXCLUDE_FILES=(
    "animations.conf"
    "hyprland.conf"
    "keybindings.conf"
    "monitors.conf"
    "nvidia.conf"
    "userprefs.conf"
    "windowrules.conf"
)
# List all available styles
styles=($(ls -d $STYLE_BASE_DIR/Style-*))

# Function to update fonts only if necessary
update_fonts() {
    # Get the list of font subfolders in the super font directory, preserving spaces
    mapfile -t current_folders < <(find "$SUPER_FONT_DIR" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sed 's|/$||')

    # Check for folders containing spaces and give a warning
    for folder in "${current_folders[@]}"; do
        if [[ "$folder" =~ [[:space:]] ]]; then
            echo "Warning: Folder '$folder' contains spaces. Please rename the folder to avoid issues."
        fi
    done

    # Create associative arrays for installed and current fonts
    declare -A installed_map
    declare -A current_map

    # Read the list of installed fonts (subfolder names) from the record file
    if [[ -f "$INSTALLED_FONTS_FILE" ]]; then
        while read -r folder; do
            installed_map["$folder"]=1
        done < "$INSTALLED_FONTS_FILE"
    fi

    # Populate current_map for faster lookup
    for folder in "${current_folders[@]}"; do
        current_map["$folder"]=1
    done

    # If installed_fonts.txt is empty, copy all subfolders to the font directory
    if [[ ${#installed_map[@]} -eq 0 ]]; then
        echo "No fonts installed. Installing all fonts from $SUPER_FONT_DIR..."
        
        # Copy all fonts from the subfolders to the local font directory
        for folder in "${!current_map[@]}"; do
            cp -r "$SUPER_FONT_DIR/$folder/" "$HOME/.local/share/fonts/"
        done

        # Update the installed_fonts.txt with subfolder names
        printf "%s\n" "${!current_map[@]}" > "$INSTALLED_FONTS_FILE"

        # Update the font cache
        echo "Updating font cache..."
        fc-cache -f
        echo "All fonts installed."
    else
        # Find new folders that need to be installed in one pass
        new_folders=()
        for folder in "${!current_map[@]}"; do
            if [[ -z "${installed_map[$folder]}" ]]; then
                new_folders+=("$folder")
            fi
        done

        # Install new fonts from folders that haven't been installed
        if [[ ${#new_folders[@]} -gt 0 ]]; then
            echo "Installing new fonts from folders: ${new_folders[*]}"
            
            for folder in "${new_folders[@]}"; do
                cp -r "$SUPER_FONT_DIR/$folder/" "$HOME/.local/share/fonts/"
            done

            # Update the installed_fonts.txt with current folder names
            printf "%s\n" "${!current_map[@]}" > "$INSTALLED_FONTS_FILE"

            # Update the font cache
            echo "Updating font cache..."
            fc-cache -f
            echo "New fonts installed."
        else
            echo "No new fonts to install."
        fi
    fi
}

# Read the previously applied style
if [[ -f "$LAST_STYLE_FILE" ]]; then
    last_style=$(cat "$LAST_STYLE_FILE")
else
    echo "No previous style detected. Skipping cleanup."
fi

# Check if any styles are available
if [ ${#styles[@]} -eq 0 ]; then
    echo "No styles found in $STYLE_BASE_DIR."
    exit 1
fi

# Display available styles
echo "Available styles:"
for i in "${!styles[@]}"; do
    style_name=$(basename "${styles[$i]}")
    echo "$((i+1)). $style_name"
done

# Prompt user for style choice
read -p "Enter the number of the style you want to apply: " choice

# Validate user choice
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#styles[@]} ]; then
    echo "Invalid choice. Please select a valid number."
    exit 1
fi

# Get the selected style directory
selected_style="${styles[$((choice-1))]}"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# If a previous style exists, clean up the old style's files before applying the new one
if [[ -n "$last_style" && -d "$STYLE_BASE_DIR/$last_style" ]]; then
    echo "Backing up hyprlock.conf"
    cp $CONFIG_DIR/hyprlock.conf $CONFIG_DIR/hyprlock.conf.bak 
    echo "Clearing files from the previous style: $last_style"

    # Find and remove only files that match between the old style and the new style
    find "$STYLE_BASE_DIR/$last_style" -type f | while read -r old_file; do
        relative_path="${old_file#$STYLE_BASE_DIR/$last_style/}"
        file_name=$(basename "$relative_path")

        # Skip deletion if the file is in the exclude list
        if [[ ! " ${EXCLUDE_FILES[*]} " =~ " ${file_name} " ]]; then
            if [[ -f "$CONFIG_DIR/$relative_path" ]]; then
                echo "Deleting $CONFIG_DIR/$relative_path"
                rm -f "$CONFIG_DIR/$relative_path"
            fi
        else
            echo "Skipping $file_name (excluded from deletion)"
        fi
    done
else    
    echo "Warning: last_applied_style.txt not found. Ignore if running first time."
fi
# Check if hyprlock.conf exists in the selected style
if [[ ! -f "$selected_style/hyprlock.conf" ]]; then
    echo "Error: hyprlock.conf not found in the selected style. Style will not be applied."
    exit 1
fi

# Write the excluded files to the exclusion file
for exclude in "${EXCLUDE_FILES[@]}"; do
    echo "$exclude" >> "$EXCLUDE_FILE"
done

# Sync the selected style to the config directory, excluding files from the list
echo "Applying $(basename "$selected_style")..."

rsync -a --exclude-from="$EXCLUDE_FILE" "$selected_style/" "$CONFIG_DIR/"

# Clean up the temporary exclude file
rm "$EXCLUDE_FILE"

echo "$(basename "$selected_style")" > "$CONFIG_DIR/last_applied_style.txt"
echo "Style: $(basename "$selected_style") has been applied."

update_fonts

echo "Style and fonts applied successfully."
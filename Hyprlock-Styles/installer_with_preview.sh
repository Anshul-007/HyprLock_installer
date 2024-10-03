#!/bin/bash

# Define the base directory for Hyprlock styles
BASE_DIR="$HOME/.config/Hyprlock-Styles"

# Define the target directory for Hypr configuration
TARGET_DIR="$HOME/.config/hypr"

# Define the Font collection directory and the record fonts installed
SUPER_FONT_DIR="$BASE_DIR/FONT_DIR"
INSTALLED_FONTS_FILE="$SUPER_FONT_DIR/installed_fonts.txt"
# Define the rsync exclusion file
EXCLUDE_FILE="/tmp/exclude_files.txt"
# List all styles (directories) under the base directory
styles=($(ls -d $BASE_DIR/Style-* | xargs -n 1 basename))
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
select_style() {

    # Read the previously applied style
    LAST_STYLE_FILE="$TARGET_DIR/last_applied_style.txt"
    # Check if last_applied_style.txt exists
    if [[ -f "$LAST_STYLE_FILE" ]]; then
        last_style=$(cat "$LAST_STYLE_FILE")
        # echo "Previous style detected: $last_style"
    else
        echo "No previous style detected. Skipping cleanup."
    fi
    # Debug: Print BASE_DIR value
    # echo "DEBUG: BASE_DIR is $BASE_DIR"

    # Get terminal dimensions
    terminal_width=$(tput cols)
    terminal_height=$(tput lines)
    # echo "DEBUG: width : $terminal_width"
    # echo "DEBUG: width : $terminal_height"

    # Calculate dynamic size (e.g., 40x20 for small terminals and up to 90x30 for larger ones)
    if [[ $terminal_width -ge 100 && $terminal_height -ge 30 ]]; then
        img_width=90
        img_height=30
    else
        img_width=$((terminal_width / 2))
        img_height=$((terminal_height / 2))
    fi

    style=$(printf "%s\n" "${styles[@]}" | fzf --prompt="Select a Hyprlock style (Q + Enter to quit): " \
        --preview='
        # Remove single quotes around the selected style if present
        style=$(echo {})
	    #echo "var style hovered is : $style"
        preview_path="'$BASE_DIR'/$style/preview.png"
        # Clear the terminal before displaying the preview
        clear  # Clear the screen
        #echo "DEBUG: Preview path: $preview_path"
        # Check if the preview file exists
        if [[ -f "$preview_path" ]]; then
            chafa --size='"$img_width"x"$img_height"' "$preview_path" 
        else
            chafa --size='"$img_width"x"$img_height"' "'$BASE_DIR'/helloaesthe.jpg" 
        fi'
        )

    if [[ -n "$style" ]]; then
        echo "You selected: $style"

        #Backing up old configuration
        cp "$TARGET_DIR/hyprlock.conf" "$TARGET_DIR/hyprlock.conf.bak"
        
        # Proceed with cleaning up the files from the last style, if applicable
        if [[ -n "$last_style" && -d "$BASE_DIR/$last_style" ]]; then
            echo "Clearing files from the previous style: $last_style"

            # Find and remove only files that match between the old style and the new style
            find "$BASE_DIR/$last_style" -type f | while read -r old_file; do
                relative_path="${old_file#$BASE_DIR/$last_style/}"
                # Get the file name from the relative path
                file_name=$(basename "$relative_path")
                # Skip deletion if the file is in the exclude list
                if [[ ! " ${EXCLUDE_FILES[*]} " =~ " ${file_name} " ]]; then
                    if [[ -f "$TARGET_DIR/$relative_path" ]]; then
                        echo "Deleting $TARGET_DIR/$relative_path"
                        rm -f "$TARGET_DIR/$relative_path"
                    fi
                else
                    echo "Skipping $file_name (excluded from deletion)"
                fi
            done
        else    
            echo "Warning: last_style_path not found. Ignore if running first time."
        fi
    else
        echo "Invalid selection. Quitting the program."
        exit 1
    fi
}

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

# Function to copy files and install fonts
apply_style() {
    local style_dir="$BASE_DIR/$style"


    # Check if hyprlock.conf exists in the selected style
    if [[ ! -f "$style_dir/hyprlock.conf" ]]; then
        echo "Error: hyprlock.conf not found in the selected style. Style will not be applied."
        exit 1
    fi

    # Write the excluded files to the exclusion file
    for exclude in "${EXCLUDE_FILES[@]}"; do
        echo "$exclude" >> "$EXCLUDE_FILE"
    done
    # Sync the selected style to the config directory, excluding files from the list
    echo "Applying $(basename "$style_dir")..."

    rsync -a --exclude-from="$EXCLUDE_FILE" "$style_dir/" "$TARGET_DIR/"

    # Clean up the temporary exclude file
    rm "$EXCLUDE_FILE"

    # Save the current style to the last_applied_style.txt
    echo "$style" > "$TARGET_DIR/last_applied_style.txt"

    update_fonts
}

# Main script execution
select_style
apply_style

# Prompt user to test the Hyprlock configuration
read -p "Do you want to test the Hyprlock configuration now? (y/n): " test_choice
case "$test_choice" in
    [Yy]* )
        echo "Testing the Hyprlock configuration..."
        # Command to test Hyprlock configuration, replace with actual test command
        hyprlock
        ;;
    [Nn]* )
        echo "Skipping Hyprlock configuration test."
        ;;
    * )
        echo "Invalid input. Skipping Hyprlock configuration test."
        ;;
esac

echo "Script finished."
clear
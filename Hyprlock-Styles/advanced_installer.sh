#!/bin/bash

### DEFINITION ###
# Define the base directory for Hyprlock styles
BASE_DIR="$HOME/.config/Hyprlock-Styles"

# Define the target directory for Hypr configuration
TARGET_DIR="$HOME/.config/hypr"

# Define the Font collection directory and the record fonts installed
SUPER_FONT_DIR="$BASE_DIR/FONT_DIR"
INSTALLED_FONTS_FILE="$SUPER_FONT_DIR/installed_fonts.txt"
# Define the rsync exclusion file
EXCLUDE_FILE="/tmp/exclude_files.txt"
# Ensure the ~/.cache/hyde directory exists
cache_wallpaper_dir="$HOME/.cache/hyde"
if [[ ! -d "$cache_wallpaper_dir" ]]; then
    mkdir -p "$cache_wallpaper_dir"
fi
# Ensure the Font collection directory exists
if [[ ! -d "$SUPER_FONT_DIR" ]]; then
    mkdir -p "$SUPER_FONT_DIR"
fi
# Ensure the installed fonts file exists
if [[ ! -f "$INSTALLED_FONTS_FILE" ]]; then
    touch "$INSTALLED_FONTS_FILE"
fi
### DEFINITION-END ###

# List all styles (directories) under the base directory
# Note: all Styles follow Style-'N' pattern
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
# Function to select a style or remove one
select_style() {

    # Read the previously applied style
    LAST_STYLE_FILE="$TARGET_DIR/last_applied_style.txt"
    if [[ -f "$LAST_STYLE_FILE" ]]; then
        last_style=$(cat "$LAST_STYLE_FILE")
    else
        echo "No previous style detected. Skipping cleanup."
    fi

    # Get terminal dimensions
    terminal_width=$(tput cols)
    terminal_height=$(tput lines)

    # Calculate dynamic size (e.g., 40x20 for small terminals and up to 90x30 for larger ones)
    if [[ $terminal_width -ge 100 && $terminal_height -ge 30 ]]; then
        img_width=90
        img_height=30
    else
        img_width=$((terminal_width / 2))
        img_height=$((terminal_height / 2))
    fi

    # Add the "Remove Style" option at the end of the styles list
    styles_with_remove=("${styles[@]}" "❌ Remove Style")

    # Show menu with fzf for style selection or remove style
    style=$(printf "%s\n" "${styles_with_remove[@]}" | fzf --prompt="Select a Hyprlock style (Q + Enter to quit): " \
        --preview='
        style=$(echo {})
        if [[ "$style" == "❌ Remove Style" ]]; then
            chafa --size='"$img_width"x"$img_height"' "'$BASE_DIR'/lara-jameson.jpg"
        else
            preview_path="'$BASE_DIR'/$style/preview.png"
            if [[ -f "$preview_path" ]]; then
                chafa --size='"$img_width"x"$img_height"' "$preview_path"
            else
                chafa --size='"$img_width"x"$img_height"' "'$BASE_DIR'/helloaesthe.jpg"
            fi
        fi'
    )

    # Check if a style was selected
    if [[ -z "$style" ]]; then
        echo "No valid option selected. Exiting."
        exit 1
    fi

    # Removal of style is redirected from here
    if [[ "$style" == "❌ Remove Style" ]]; then
        echo "⚠️ Warning: This will permanently remove any selected style. Proceed(Y/n): "
        read confirmation
        if [[ "$confirmation" == "Y" || "$confirmation" == "y" ]]; then
            remove_style
            exit 0
        else
            echo "Removal cancelled."
            exit 0
        fi
    fi

    # If a previous style exists, clean up the old style's files before applying the new one
    if [[ -n "$last_style" && -d "$BASE_DIR/$last_style" ]]; then
        echo "Backing up hyprlock.conf"
        cp $TARGET_DIR/hyprlock.conf $TARGET_DIR/hyprlock.conf.bak 
        echo "Clearing files from the previous style: $last_style"

        # Find and remove only files that match between the old style and the new style
        find "$BASE_DIR/$last_style" -type f | while read -r old_file; do
            relative_path="${old_file#$BASE_DIR/$last_style/}"
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
        echo "Warning: last_applied_style.txt not found. Ignore if running first time."
    fi
}

# Function to remove a style
remove_style() {
    # List all styles in the base directory again
    styles=($(ls -d $BASE_DIR/Style-* | xargs -n 1 basename))

    # Use fzf to select a style to remove
    style_to_remove=$(printf "%s\n" "${styles[@]}" | fzf --prompt="Select a style to remove (Ctrl+C to quit): ")

    if [[ -n "$style_to_remove" ]]; then
        echo "You selected: $style_to_remove for removal."

        # Ask user to type their username ($USER) for confirmation
        read -p "Type your username ($USER) to confirm deletion of $style_to_remove (This action is irreversible): " confirmation

        if [[ "$confirmation" == "$USER" ]]; then
            # Check if the directory exists
            style_dir="$BASE_DIR/$style_to_remove"
            if [[ -d "$style_dir" ]]; then
                echo "Removing $style_dir..."
                rm -rf "$style_dir"
                echo "Style $style_to_remove has been removed from $BASE_DIR."
            else
                echo "Style directory $style_dir does not exist."
            fi
        else
            echo "Confirmation failed. No style was removed."
        fi
    else
        echo "Invalid selection. No style removed."
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


apply_style() {
    local style_dir="$BASE_DIR/$style"

    # Check if hyprlock.conf exists in the selected style
    if [[ ! -f "$style_dir/hyprlock.conf" ]]; then
        echo "Error: hyprlock.conf not found in the selected style. Style will not be applied."
        exit 1
    fi

    # Check if any .png or .jpg file exists in the style directory
    img_found=false
    for img_file in "$style_dir"/*.{png,jpg,jpeg}; do
        if [[ -f "$img_file" ]]; then
            img_found=true
            break
        fi
    done

    # Write the excluded files to the exclusion file
    for exclude in "${EXCLUDE_FILES[@]}"; do
        echo "$exclude" >> "$EXCLUDE_FILE"
    done

    if [[ "$img_found" == false ]]; then
        # No image found, use the default wallpaper from .cache
        echo "No image file found in the style. Using wallpaper from .cache."
    else
        echo "Applying style's own image from the style folder."
    fi

    # Sync the selected style to the config directory, excluding files from the list
    echo "Applying $(basename "$style_dir")..."

    rsync -a --exclude-from="$EXCLUDE_FILE" "$style_dir/" "$TARGET_DIR/"

    # Clean up the temporary exclude file
    rm "$EXCLUDE_FILE"
    # Save the current style to the last_applied_style.txt
    echo "$style" > "$TARGET_DIR/last_applied_style.txt"

    echo "Style: $style has been applied."

    update_fonts
}

# Main execution flow
select_style

# If a style was selected, apply it
if [[ "$style" != "Remove Style" ]]; then
    apply_style

    # Prompt user to test the Hyprlock configuration
    read -p "Do you want to test the Hyprlock configuration now? (y/n): " test_choice
    case "$test_choice" in
        [Yy]* )
            echo "Testing the Hyprlock configuration..."
            hyprlock
            ;;
        [Nn]* )
            echo "Skipping Hyprlock configuration test."
            ;;
        * )
            echo "Invalid input. Skipping Hyprlock configuration test."
            ;;
    esac
fi

echo "Script finished."
clear

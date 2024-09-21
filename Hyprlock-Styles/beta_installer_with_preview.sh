#!/bin/bash

# Define the base directory for Hyprlock styles
BASE_DIR="$HOME/.config/Hyprlock-Styles"

# Define the target directory for Hypr configuration
TARGET_DIR="$HOME/.config/hypr"

# List all styles (directories) under the base directory
styles=($(ls -d "$BASE_DIR"/*/ | xargs -n 1 basename))

# Function to select a style or remove one
select_style() {

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

    # Read the previously applied style
    LAST_STYLE_FILE="$TARGET_DIR/last_applied_style.txt"
    # Check if last_applied_style.txt exists
    if [[ -f "$LAST_STYLE_FILE" ]]; then
        last_style=$(cat "$LAST_STYLE_FILE")
    else
        echo "No previous style detected. Skipping cleanup."
    fi

    # Get terminal dimensions
    terminal_width=$(tput cols)
    terminal_height=$(tput lines)

    # Calculate dynamic size (e.g., 40x20 for small terminals and up to 100x30 for larger ones)
    if [[ $terminal_width -ge 100 && $terminal_height -ge 30 ]]; then
        img_width=100
        img_height=30
    else
        img_width=$((terminal_width / 2))
        img_height=$((terminal_height / 2))
    fi

    # Add the "Remove Style" option at the end of the styles list
    styles_with_remove=("${styles[@]}" "❌Remove Style")

    # Show menu with fzf for style selection or remove style
    style=$(printf "%s\n" "${styles_with_remove[@]}" | fzf --prompt="Select a Hyprlock style (Q + Enter to quit): " \
        --preview='
        style=$(echo {})
        if [[ "$style" == "❌Remove Style" ]]; then
            echo "Select this option to remove the currently applied style."
        else
            preview_path="'$BASE_DIR'/$style/preview.png"
            if [[ -f "$preview_path" ]]; then
                chafa --size='"$img_width"x"$img_height"' "$preview_path"
            else
                echo "No preview available for this style."
            fi
        fi'
    )

    # Check if a style was selected
    if [[ -z "$style" ]]; then
        echo "No valid option selected. Exiting."
        exit 1
    fi

    # Continue with the rest of the script only if a valid option was selected
    if [[ "$style" == "❌Remove Style" ]]; then
        echo "Type $USER to confirm choice: "
        read 
        remove_style
        exit 0
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
        echo "Warning: last_style_path not found. Ignore if running first time."
    fi
}

# Function to remove a style
remove_style() {
    # List all styles in the base directory again
    styles=($(ls -d "$BASE_DIR"/*/ | xargs -n 1 basename))

    # Use fzf to select a style to remove
    style_to_remove=$(printf "%s\n" "${styles[@]}" | fzf --prompt="Select a style to remove: ")

    if [[ -n "$style_to_remove" ]]; then
        echo "You selected: $style_to_remove for removal."

        # Ask user to type their username ($USER) for confirmation
        read -p "Type your username ($USER) to confirm deletion of $style_to_remove(This action is irreversible): " confirmation

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

# Function to copy files and install fonts
apply_style() {
    local style_dir="$BASE_DIR/$style"

    # Copy all contents from the selected style to the target directory
    echo "Copying $style files..."
    cp -r "$style_dir/"* "$TARGET_DIR/"

    # Save the current style to the last_applied_style.txt
    echo "$style" > "$TARGET_DIR/last_applied_style.txt"

    echo "Installing required fonts..."
    local font_dir="$style_dir/Fonts"

    if [[ -d "$font_dir" ]]; then
        for font in "$font_dir"/*; do
            if [[ -d "$font" ]]; then
                cp -r "$font" "$HOME/.local/share/fonts/"
            elif [[ -f "$font" ]]; then
                cp "$font" "$HOME/.local/share/fonts/"
            fi
        done
        echo "Updating font cache..."
        fc-cache -f 
    else
        echo "No font directory found in $style_dir."
    fi
}

# Main script execution
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

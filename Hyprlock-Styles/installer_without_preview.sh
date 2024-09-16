#!/bin/bash

# Define the base directory for Hyprlock styles
BASE_DIR="$HOME/.config/Hyprlock-Styles"

# Define the target directory for Hypr configuration
TARGET_DIR="$HOME/.config/hypr"

# List all styles (directories) under the base directory
styles=($(ls -d "$BASE_DIR"/*/ | xargs -n 1 basename))

# Function to display options and get the user's selection using fzf
select_style() {
    style=$(printf "%s\n" "${styles[@]}" | fzf --prompt="Select a Hyprlock style (Q + Enter to quit): " --height=12)
    if [[ -n "$style" ]]; then
        echo "You selected: $style"
    else
        echo "Invalid selection. Quitting the program."
        exit 1
    fi
}

# Function to copy files and install fonts
apply_style() {
    local style_dir="$BASE_DIR/$style"

    # Copy all contents from the selected style to the target directory
    echo "Copying $style files..."
    cp -r "$style_dir/"* "$TARGET_DIR/"

    echo "Installing required fonts..."
    local font_dir="$style_dir/Fonts"

    if [[ -d "$font_dir" ]]; then
        echo "Installing fonts from $font_dir..."
        for font in "$font_dir"/*; do
            if [[ -d "$font" ]]; then
                # Copy only directories (fonts)
                cp -r "$font" "$HOME/.local/share/fonts/"
            elif [[ -f "$font" ]]; then
                # Copy individual font files
                cp "$font" "$HOME/.local/share/fonts/"
            fi
        done
        echo "Updating font cache..."
        fc-cache -f 
    else
        echo "No font directory found in $style_dir."
    fi

    echo "Updating Hyprlock configuration..."
    cp "$TARGET_DIR/hyprlock.conf" "$TARGET_DIR/hyprlock.conf.bak"
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


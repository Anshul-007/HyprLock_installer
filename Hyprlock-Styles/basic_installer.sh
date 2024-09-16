#!/bin/bash

# Define the base directory for the styles
STYLE_BASE_DIR="$HOME/.config/Hyprlock-Styles"
CONFIG_DIR="$HOME/.config/hypr"

# List all directories in the style base directory
styles=($(ls -d $STYLE_BASE_DIR/Style-*))

# Check if there are any styles available
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

# Prompt user to choose a style
read -p "Enter the number of the style you want to apply: " choice

# Validate the user's choice
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#styles[@]} ]; then
    echo "Invalid choice. Please select a valid number."
    exit 1
fi

# Get the selected style directory
selected_style="${styles[$((choice-1))]}"

# Create the config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Apply the selected style
echo "Applying $(basename "$selected_style")..."
cp -r "$selected_style/"* "$CONFIG_DIR/"

echo "Style applied successfully."

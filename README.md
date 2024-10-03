# Hyprlock Styles Installer

[![Hyprlock Styles Demo](https://img.youtube.com/vi/4Qes9o3ifHQ/0.jpg)](https://www.youtube.com/watch?v=4Qes9o3ifHQ)


This repository provides multiple Hyprlock styles and includes three versions of an installation script:

1. **Basic Installer**
2. **Installer with Preview**
3. **Advanced Installer**

`Note`: Dynamic wallpaper only works on Hyde project

These scripts allow you to apply different styles to your Hyprlock configuration with options to preview styles before applying them.

## Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [Basic Installer](#basic-installer)
  - [Installer without Preview](#installer-without-preview)
  - [Installer with Preview](#installer-with-preview)
- [Contributing](#contributing)
- [Credits](#credits)
- [License](#license)

## Requirements

Before using the scripts, ensure the following packages are installed on your system:

1. **Hyprlock** (Hyprland's simple, yet multi-threaded and GPU-accelerated screen locking utility.)
    - Install via (For Arch based systems): `pacman -S hyprlock` or `yay -S hyprlock-git`(for latest version)
    - For other Distro: [hyprlock-github](https://github.com/hyprwm/hyprlock)

2. **fzf** (For interactive style selection)
   - Install via: `sudo pacman -S fzf` (Arch-based systems) or `sudo apt install fzf` (Debian-based systems)

3. **chafa** (For displaying previews in the terminal)
   - Install via: `sudo pacman -S chafa` or `sudo apt install chafa`

4. **fc-cache** (For managing font cache)
   - This is typically included in font management packages like `fontconfig`, which is installed by default in most Linux distributions.

5. **Kitty Terminal** (for certain preview features)
   - Install via: `sudo pacman -S kitty` or `sudo apt install kitty`

7. Optional: **Imagemagick** (for converting image formats)
    - Install via: `sudo pacman -S imagemagick` or `sudo apt install imagemagick`

6. **Optional feature** (for enabling dynamic wallpaper on hyprlock)
    - This installer works best on Hyde project 
    - Check the Hyde project [here](https://github.com/HyDE-Project/Hyde-cli?tab=readme-ov-file#installation)
    - OR If you have a directory where all the dynamic wallpapers are kept in a `png` only format you can specify the path in the `hyprlock.conf` file of `Style-wallpaper` directory
## Installation

1. **Clone the repository** to your local machine:

   ```bash
   git clone https://github.com/Anshul-007/HyprLock_installer
   cp -r HyprLock_installer/Hyprlock-Styles/ ~/.config/Hyprlock-Styles
   cd ~/.config/Hyprlock-Styles
    ```
2. **Choose your installer:**
    - Basic Installer: `basic_installer.sh`
    - Installer with preview: `installer_with_preview.sh` **(Recommended)**
    - Installer with delete feature: `advanced_installer.sh`

    Make the desired script executable:

    ```bash
    chmod +x installer_with_preview.sh # Replace with your chosen script
    ```
    
3. **Optional feature for dynamic wallpaper**
    - For those who are on Hyde project can `add` below in ~/.local/share/bin/swwwallpaper.sh -> Wall_Cache()
    ```bash
    if [[ "${wallList[setIndex]}" == *.gif ]]; then
        echo "GIFs are not supported by hyprlock yet..."
    else
        # Convert current wallpaper to PNG and store in .cache/hyde as wall.png
        magick convert "${wallList[setIndex]}" "${cacheDir}/wall.png"
    fi
    ```
    - For those who are not on Hyde project need to make a directory where all wallpapers are dynamically changed and stored and then link that path to hyprlock.conf file in Style_wallpaper folder

        **Note: Use png format if possible or convert your images to png using imagemagick since hyprlock.conf can't be updated dynamically
## Usage 

### Basic Installer
This script will apply the selected style to your Hyrplock configuration. It doesn't offer preview functionality:

```bash
./basic_installer.sh
```

### Installer with Preview
This version allows you to see a preview of the styles before applying them:

```bash
./installer_with_preview.sh
```

### Advanced Installer with removal and dynamic wallpaper
This version allows you to preview and delete a style permanently:

```bash
./advanced_installer.sh
```

You will be prompted to select a style using `fzf`. If you have the preview feature enabled, `chafa` will display the style preview in your terminal and this works best on `kitty` terminal.

`Update: All installers are packaged with cache functionality`

**WARNING**: If you have your `hyprlock.conf` file in `~/.config/hypr` directory please back it up as this script may delete if ran more than one time.

**NOTE:** To test the hyprlock press `y` when prompted or you can explicitly type `hyprlock` in terminal

## Font Installation 
If the style contains fonts, the installer will automatically copy them to your local fonts directory (`$HOME/.local/share/fonts/`) and update the font cache using fc-cache

In case of any erroneous fonts you can explicitly install the required fonts for that style

## Contributing 
Feel free to to contribute to this repository by submitting issues or pull requests. Any contributions, whether bug reports, code improvements, or new styles, are welcome.

1. If you want to add new styles, please ensure that:
    - The style has a proper preview image (`preview.png`) if applicable.
    - Fonts are included in the `Fonts` folder, if required by the style.
    - The style works with the existing Hyprlock configuration

2. The structure of Style-`N` directory should be of this structure:
    ```
    .config/Hyprlock-Styles/Style-N
    ├── hyprlock.conf
    ├── hyprlock.png
    ├── preview.png
    ├── Scripts
    │   └── songdetail.sh
    └── user.jfif

    .config/Hyprlock-Styles/FONT_DIR
    └── A_Font_directory_without_spaced
        └──font.ttf
    ```

## Credits
- This project is possible by all the open source projects and big thanks to [Mr. Vivek Rajan](https://github.com/MrVivekRajan/Hyprlock-Styles) for all the styles. 
- Also check out [Khurasan](https://fontesk.com/designer/syaf-rizal/) for awesome fonts.

## License
This project is licensed under the [GPL-3.0 License](https://www.gnu.org/licenses/gpl-3.0.en.html), since some of the style are derived from other GPL-licensed repositories.
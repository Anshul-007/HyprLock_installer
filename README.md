# Hyprlock Styles Installer

[![Hyprlock Styles Demo](https://img.youtube.com/vi/4Qes9o3ifHQ/0.jpg)](https://www.youtube.com/watch?v=4Qes9o3ifHQ)


This repository provides multiple Hyprlock styles and includes three versions of an installation script:

1. **Basic Installer**
2. **Installer without Preview**
3. **Installer with Preview**

These scripts allow you to apply different styles to your Hyprlock configuration with options to preview styles before applying them.

## Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [Basic Installer](#basic-installer)
  - [Installer without Preview](#installer-without-preview)
  - [Installer with Preview](#installer-with-preview)
- [Contributing](#contributing)
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

## Installation

1. **Clone the repository** to your local machine:

   ```bash
   git clone https://github.com/Anshul-007/HyprLock_installer
   cp -r HyprLock_installer/Hyprlock-Styles/ ~/.config/Hyprlock-Styles
   cd ~/.config/Hyprlock-Styles
    ```
2. **Choose your installer:**
    - Basic Installer: `basic_installer.sh`
    - Installer without preview: `installer_without_preview.sh`
    - Installer with preview: `installer_with_preview.sh`

    Make the desired script executable:

    ```bash
    chmod +x installer_with_preview.sh # Replace with your chosen script
    ```
## Usage 

### Basic Installer
Run the basic installer script: 

```bash
./basic_installer.sh
```

This script will apply the selected style to your Hyrplock configuration. It doesn't offer preview functionality

### Installer without Preview
This script works similarly to the basic installer but skips the preview of styles:

```bash
./installer_without_preview.sh
```
It also applies the selected style but without previewing any images of the styles in the terminal.

### Installer with Preview
This version allows you to see a preview of the styles before applying them:

```bash
./installer_with_preview.sh
```

You will be prompted to select a style using `fzf`. If you have the preview feature enabled, `chafa` will display the style preview in your terminal.

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
    ├── Fonts
    │   ├── JetBrains
    │   │   └── JetBrains Mono Nerd.ttf
    │   └── SF Pro Display
    │       ├── SF Pro Display Bold.otf
    │       └── SF Pro Display Regular.otf
    ├── hyprlock.conf
    ├── hyprlock.png
    ├── preview.png
    ├── Scripts
    │   └── songdetail.sh
    └── user.jfif
    ```

## License
This project is licensed under the [GPL-3.0 License](https://www.gnu.org/licenses/gpl-3.0.en.html), since some of the style are derived from other GPL-licensed repositories.
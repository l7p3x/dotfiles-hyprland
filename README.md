<div align="center">
  <img src="screenshots/hyprshot2.png" alt="Hyprland Preview" width="100%">
  <h1>Hyprland Dotfiles</h1>
  <p>A minimalist and reproducible Hyprland (Wayland) configuration focused on aesthetics, performance, simplicity, and a clean user experience.</p>
</div>

<p align="center">
  <a href="#installation"><img src="https://img.shields.io/badge/Hyprland-Dotfiles-blue.svg" alt="Hyprland Dotfiles"></a>
  <a href="https://github.com/l7p3x/dotfiles-hyprland/stargazers"><img src="https://img.shields.io/github/stars/l7p3x/dotfiles-hyprland.svg" alt="GitHub stars"></a>
</p>

> [!WARNING]
> The `bootstrap` command and automatic package installation are **Arch-based only** (Arch, Manjaro, CachyOS, EndeavourOS). On other distros, use `./install.sh install` to deploy configs only and install dependencies manually.

---

## Overview

**Hyprland Dotfiles** is a modern, minimalist Wayland configuration designed to stay out of your way while looking distinctive. Built around clean design principles, it emphasizes clarity, smooth motion, and simplicity.

It features a sleek dark interface, a fluid user experience, and subtle visual details that make your desktop both beautiful and functional. This setup is designed to be lightweight, modular, and easy to maintain.

## Features

- **Smooth Animations**: Rounded corners, blur effects, and transparent inactive windows.
- **Dark Minimalist Interface**: Easy on the eyes with a clean, modern aesthetic.
- **Session Selector**: Integrated and intuitive workspace switching.
- **Power Controls**: Quick access to system monitor, launcher, and file manager.
- **Highly Customizable**: Modular Hyprland config, GTK theming via nwg-look + xsettingsd.

### Preview

<div align="center">

| Launcher | Terminal |
|---|---|
| ![](screenshots/hyprshot1.png) | ![](screenshots/hyprshot2.png) |
| Browser | Editor |
|---|---|
| ![](screenshots/hyprshot3.png) | ![](screenshots/hyprshot4.png) |

</div>

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/l7p3x/dotfiles-hyprland.git ~/.local/share/dotfiles-hyprland
cd ~/.local/share/dotfiles-hyprland
```

### 2. Install the Dotfiles
Run the installer with the desired deployment mode:
```bash
./install.sh
```
Default behavior: bootstrap + install.

### 3. Deployment Modes

| Command | Description |
|--------|------------|
| `(none)` | Full auto |
| `bootstrap` | Install dependencies |
| `install` | Deploy dotfiles |
| `update` | Update files |
| `rollback` | Restore backup |
| `status` | Show state |

```bash
./install.sh [command]
```

> **Warning:** Use `--dry-run` before applying changes. Do not move the repo if using `--symlink`.

### 4. Manual Installation
```bash
cp -r .config/* ~/.config/
cp .zshrc ~/
cp .gtkrc-2.0 ~/
mkdir -p ~/Pictures/Wallpapers
cp Wallpapers/* ~/Pictures/Wallpapers/
```

## Customization

### Keybindings (ALT as main modifier)

| Keybind | Action |
|--------|--------|
| ALT + T | Open terminal (Foot) |
| ALT + E | Open file manager (Thunar) |
| ALT + D | Open app launcher (Hyprlauncher) |
| ALT + F | Open browser (Zen Browser / Firefox) |
| ALT + Q | Close active window |
| ALT + V | Toggle floating mode |
| WIN + R | Reload Hyprland configuration |
| WIN + F1 | Toggle gamemode |
| ALT + 1-0 | Switch workspaces |
| ALT + SHIFT + 1-0 | Move window to workspace |

*Looking for advanced tweaks?*
Animations, layout, and behavior require editing the Hyprland config files directly inside `.config/hypr/conf/`.

## Directory Structure

```text
.
├── .zshrc
├── .gtkrc-2.0
├── .config/
│   ├── hypr/
│   │   ├── conf/
│   │   └── assets/
│   ├── waybar/
│   ├── foot/
│   ├── mako/
│   ├── btop/
│   ├── gtk-3.0/
│   ├── gtk-4.0/
│   ├── Thunar/
│   ├── xfce4/
│   ├── nwg-look/
│   ├── xsettingsd/
│   └── zed/
├── Wallpapers/
├── screenshots/
├── install.sh
├── README.md
└── .gitignore
```

## Dependencies

**Core:**
- hyprland
- waybar
- foot
- mako

**Hypr ecosystem:**
- hyprpaper
- hypridle
- hyprlauncher

**Utilities:**
- thunar
- btop
- hyprshot
- zsh
- nwg-look
- xsettingsd
- zen-browser

## Uninstallation

To remove the dotfiles, delete the repo and restore your previous configs:

```bash
rm -rf ~/.local/share/dotfiles-hyprland
```
Then use `rollback` if you ran the installer, or manually restore your previous `~/.config` entries.

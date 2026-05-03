# Hyprland Dotfiles

A minimalist and reproducible Hyprland (Wayland) configuration focused on aesthetics, performance, simplicity, and a clean user experience.

This setup is designed to be lightweight, modular, and easy to maintain.

## Table of Contents
- [Features](#features)
- [Components](#components)
- [Installation](#installation)
- [Dependencies](#dependencies)
- [Repository Structure](#repository-structure)
- [Manual Installation](#manual-installation)
- [Notes](#notes)
- [Preview](#preview)

---

## Features

### Keybindings (ALT as main modifier)
- ALT + T: Open terminal (Foot)
- ALT + E: Open file manager (Thunar)
- ALT + R: Open app launcher (Hyprlauncher)
- ALT + F: Open browser (Zen Browser / Firefox)
- ALT + Q: Close active window
- ALT + V: Toggle floating mode
- ALT + S: Toggle scratchpad (Spotify workspace)
- WIN + R: Reload Hyprland configuration
- WIN + F1: Toggle gamemode
- ALT + 1-0: Switch workspaces
- ALT + SHIFT + 1-0: Move window to workspace

---

### System Features
- Spotify scratchpad on a dedicated workspace
- Screenshot support via hyprshot
- Gamemode toggle with notification feedback
- System monitor (btop)
- Modular Hyprland config
- GTK theming via nwg-look + xsettingsd

---

### Appearance
- Rounded corners (8px)
- Blur effects enabled
- Transparent inactive windows
- Custom cursor (Qogir)
- GTK theming (GTK2/3/4)
- Clean Waybar styling

---

## Components

- Window Manager: Hyprland
- Bar: Waybar
- Terminal: Foot
- Notifications: Mako
- Shell: Zsh
- File Manager: Thunar
- System Monitor: btop

---

## Installation

Clone the repository:

\`\`\`bash
git clone https://github.com/YOUR_USER/dotfiles-hyprland.git ~/.local/share/dotfiles-hyprland
cd ~/.local/share/dotfiles-hyprland
./install.sh
\`\`\`

Default behavior:
bootstrap + install

---

### Deployment Modes

- default → copies files to \$HOME
- --symlink → creates symlinks

⚠️ Do not move the repo if using symlinks.

---

### Installer Commands

\`\`\`bash
./install.sh [command]
\`\`\`

| Command | Description |
|--------|------------|
| (none) | Full auto |
| bootstrap | Install dependencies |
| install | Deploy dotfiles |
| update | Update files |
| rollback | Restore backup |
| status | Show state |

---

## Dependencies

Core:
- hyprland
- waybar
- foot
- mako

Hypr ecosystem:
- hyprpaper
- hypridle
- hyprlauncher

Utilities:
- thunar
- btop
- hyprshot
- zsh
- nwg-look
- xsettingsd
- zen-browser

---

## Repository Structure

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

---

## Manual Installation

\`\`\`bash
cp -r .config/* ~/.config/
cp .zshrc ~/
cp .gtkrc-2.0 ~/
mkdir -p ~/Pictures/Wallpapers
cp Wallpapers/* ~/Pictures/Wallpapers/
\`\`\`

---

## Notes

- Optimized for Arch-based systems
- Modular and easy to tweak
- Use --dry-run before applying changes

---

## Preview

| Launcher | Terminal |
|---|---|
| ![](screenshots/hyprshot1.png) | ![](screenshots/hyprshot2.png) |

| Browser | Editor |
|---|---|
| ![](screenshots/hyprshot3.png) | ![](screenshots/hyprshot4.png) |

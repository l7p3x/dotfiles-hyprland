# Hyprland Dotfiles

Minimalist Hyprland (Wayland) configuration focused on aesthetics and functionality.

## Components

- **Window Manager**: Hyprland with Master/Dwindle layouts, custom animations, blur, and transparency effects
- **Bar**: Waybar with Spotify integration, app launchers, system monitoring, and weather widget
- **Terminal**: Foot with JetBrains Mono Nerd Font
- **Notifications**: Dunst with custom themes and gamemode indicators
- **Shell**: Bash with Ble.sh enhancement and custom prompt ("ふあん")

## Features

### Keybindings (ALT as main modifier)
- `ALT + T`: Open terminal (Foot)
- `ALT + E`: Open file manager (Nautilus)
- `ALT + R`: Open app launcher (Bemenu)
- `ALT + F`: Open browser (Firefox)
- `ALT + Q`: Close active window
- `ALT + V`: Toggle floating mode
- `ALT + S`: Toggle scratchpad (Spotify workspace)
- `WIN + R`: Reload Hyprland configuration
- `WIN + F1`: Toggle gamemode
- `ALT + 1-0`: Switch workspaces
- `ALT + SHIFT + 1-0`: Move window to workspace

### System Features
- Automatic Spotify scratchpad on special workspace
- Screenshot tools (hyprshot) for full screen and region capture
- Gamemode toggle with visual notifications
- System monitor (btop) accessible via keybind
- Quick configuration reload with notification

### Appearance
- Custom workspace icons
- Transparent inactive windows (70% opacity)
- Blur effects enabled
- Rounded corners (8px)
- Custom cursor theme (Qogir)
- YAMIS icon theme (auto-installed)

## Installation

```bash
./install.sh
```

The installation script will:
1. Move configuration files to your home directory
2. Clone YAMIS icon theme repository
3. Install monochrome icons to `~/.local/share/icons`

## Dependencies

- hyprland
- waybar
- foot
- dunst
- hyprpaper
- hypridle
- bemenu
- nautilus
- firefox
- btop
- playerctl
- hyprshot
- ble.sh

## Structure

```
.
├── .bashrc              # Shell configuration with custom prompt
├── .blerc               # Ble.sh configuration
├── .config/
│   ├── hypr/            # Hyprland configurations
│   │   ├── hyprland.conf
│   │   ├── hyprpaper.conf
│   │   ├── hypridle.conf
│   │   └── assets/      # Scripts (gamemode, toggle)
│   ├── waybar/          # Bar configuration
│   │   ├── config.jsonc
│   │   └── style.css
│   ├── foot/            # Terminal emulator settings
│   │   └── foot.ini
│   └── dunst/           # Notification daemon
│       ├── dunstrc
│       └── icons/
└── install.sh           # Installation script
```

## License

Personal dotfiles - feel free to use and modify.

# 🖃 OmaStamp

> **Desktop Background Logo & Watermark Overlay Plugin for Omarchy.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Omarchy](https://img.shields.io/badge/Omarchy-Quattro-blue.svg)](https://omarchy.org)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%2F%20Wayland%20%2F%20Hyprland-informational.svg)]()

**OmaStamp** stamps clean, customizable logos, distro crests, vector insignias, or typographic monograms directly over your desktop wallpaper. It runs seamlessly behind all application windows on Wayland LayerShell (`WlrLayer.Bottom`), completely transparent to mouse clicks (`mask: Region {}`).

---

## ✨ Features

- 🖼️ **3 Powerful Overlay Modes**:
  - **Preset Vector Crests**: Bundled high-resolution SVG insignias (*Omarchy*, *Arch Linux*, *Hyprland*, *Tux Linux*, *Cyber Hex*, *Retro 80s Globe*, *Arcade Ghost*, *Terminal Badge*, *Minimal Star*).
  - **Custom Image / Logo File**: Stamp any custom PNG, SVG, JPG, or WebP logo with integrated file browsing.
  - **Typographic Watermark**: Custom text monogram + secondary slogan/system specs with uppercase letter-spacing.
- 🎯 **9-Point Interactive Placement Matrix**:
  - Center, Top-Left, Top-Center, Top-Right, Center-Left, Center-Right, Bottom-Left, Bottom-Center, Bottom-Right.
  - Fine-grained margin and offset sliders.
- 🎨 **Adaptive Omarchy Theme Tinting**:
  - **Theme Accent** (`Color.accent`): Matches your active Omarchy theme colors dynamically.
  - **Theme Foreground / Text**: Matches theme font color.
  - **Original Colors**: Unfiltered raw colors for full-color artwork.
  - **Monochrome White / Black** or **Custom Hex Color**.
- 🎛️ **Full Visual Customization**:
  - Live Opacity slider (1% to 100%).
  - Size slider (32px to 800px).
  - Rotation angle slider (-180° to +180° with smooth animated transitions).
  - Optional subtle drop shadow effect.
- 🖱️ **Zero-Interference Click-Through**:
  - Built with an empty Wayland input region (`mask: Region {}`), so desktop wallpaper double-clicks (wallpaper/theme switcher) and mouse actions pass straight through with zero lag or blocking.
- 🖥️ **Status Bar Widget & Studio Popup**:
  - Left-click status bar icon: Opens interactive **OmaStamp Studio** control popup.
  - Right-click status bar icon: Instant on/off toggle.
  - Middle-click status bar icon: Quick cycle to next logo preset.
- 💻 **Standalone CLI & IPC Controller (`omastamp`)**:
  - Control every aspect of the stamp from scripts, terminals, or Hyprland keybindings.

---

## 🚀 CLI Commands

```bash
# Toggle overlay on/off
omastamp toggle
omastamp on
omastamp off

# Switch logo presets
omastamp list-presets
omastamp set-preset arch
omastamp next-preset

# Custom image & text
omastamp set-image ~/Pictures/my-branding.svg
omastamp set-text "OMARCHY" "ARCH LINUX EDITION"

# Adjust alignment & dimensions
omastamp set-position center
omastamp set-position bottom-right
omastamp set-size 320
omastamp set-opacity 25
omastamp set-rotation -15
omastamp set-tint theme-accent
omastamp set-shadow true

# Status & Reset
omastamp status
omastamp reset
```

---

## ⌨️ Hyprland Keybinding Examples

Add quick shortcuts in `~/.config/hypr/hyprland.conf`:

```ini
# Toggle desktop stamp overlay
bind = SUPER SHIFT, S, exec, omastamp toggle

# Cycle through logo presets
bind = SUPER CTRL, S, exec, omastamp next-preset
```

---

## 📦 Installation

```bash
cd /home/dorneles/Projects/omastamp
./install.sh
```

To remove:
```bash
./uninstall.sh
```

---

## 📄 License

MIT License © 2026 Juliano Dorneles

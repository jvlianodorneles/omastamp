#!/usr/bin/env python3
"""
OmaStamp Controller & CLI Backend
Manages desktop logo overlay configuration, presets, typography fonts, and state persistence.
"""

import sys
import os
import json
import shutil
import subprocess
import argparse
from pathlib import Path

STATE_DIR = Path.home() / ".local" / "state" / "omarchy" / "omastamp"
CONFIG_FILE = STATE_DIR / "config.json"

PRESETS = [
    {"id": "omarchy", "name": "Omarchy Mark", "desc": "Authentic geometric square monogram"},
    {"id": "omarchy-text", "name": "Omarchy Wordmark", "desc": "Official typographic block logo"},
    {"id": "arch", "name": "Arch Linux", "desc": "Iconic Arch Linux crest swoosh"},
    {"id": "hyprland", "name": "Hyprland", "desc": "Dynamic compositor vector flame"},
    {"id": "tux", "name": "Tux Penguin", "desc": "Classic Linux mascot silhouette"},
    {"id": "cyber-hex", "name": "Cyber Hexagon", "desc": "Geometric matrix and circuit emblem"},
    {"id": "retro-globe", "name": "Retro 80s Globe", "desc": "Wireframe perspective sphere"},
    {"id": "arcade-ghost", "name": "Arcade Ghost", "desc": "Retro 8-bit arcade pixel ghost"},
    {"id": "terminal", "name": "Dev Terminal", "desc": "Code prompt prompt badge"},
    {"id": "minimal-star", "name": "Minimal Star", "desc": "Modern 4-point starburst compass"}
]

FONTS = [
    {"id": "modern-sans", "name": "Modern Sans", "type": "pro", "desc": "Clean geometric sans-serif"},
    {"id": "mono", "name": "Monospace", "type": "pro", "desc": "Terminal developer code font"},
    {"id": "serif", "name": "Classic Serif", "type": "pro", "desc": "Editorial elegant serif"},
    {"id": "display", "name": "Display Impact", "type": "pro", "desc": "Heavy bold headline font"},
    {"id": "condensed", "name": "Tall Condensed", "type": "pro", "desc": "Condensed poster typography"},
    {"id": "slant", "name": "Slant", "type": "ascii", "desc": "Italicized ASCII art font"},
    {"id": "standard", "name": "Standard", "type": "ascii", "desc": "Classic ANSI/ASCII banner"},
    {"id": "block", "name": "Block", "type": "ascii", "desc": "Solid 3D block characters"},
    {"id": "banner", "name": "Banner", "type": "ascii", "desc": "Large bold banner characters"},
    {"id": "doom", "name": "Doom", "type": "ascii", "desc": "Retro Doom gaming font"},
    {"id": "epic", "name": "Epic", "type": "ascii", "desc": "Dramatic high-impact font"},
    {"id": "starwars", "name": "Star Wars", "type": "ascii", "desc": "Sci-Fi iconic logo font"},
    {"id": "isometric1", "name": "Isometric", "type": "ascii", "desc": "3D isometric perspective font"},
    {"id": "graffiti", "name": "Graffiti", "type": "ascii", "desc": "Urban street art letters"},
    {"id": "speed", "name": "Speed", "type": "ascii", "desc": "Fast italicized stroke font"},
    {"id": "sub-zero", "name": "Sub-Zero", "type": "ascii", "desc": "Chiseled frosty block font"},
    {"id": "cyberlarge", "name": "Cyberlarge", "type": "ascii", "desc": "Cyberpunk terminal banner"},
    {"id": "shadow", "name": "Shadow", "type": "ascii", "desc": "Outlined shaded letters"},
    {"id": "alligator", "name": "Alligator", "type": "ascii", "desc": "Grooved tech characters"},
    {"id": "delta_corps_priest_1", "name": "Delta Corps", "type": "ascii", "desc": "Signature OmaSaver combat font"}
]

POSITIONS = [
    "center",
    "top-left",
    "top-center",
    "top-right",
    "center-left",
    "center-right",
    "bottom-left",
    "bottom-center",
    "bottom-right"
]

TINT_MODES = [
    "theme-accent",
    "theme-fg",
    "original",
    "white",
    "black",
    "custom"
]

DEFAULTS = {
    "enabled": True,
    "mode": "preset",
    "preset": "omarchy",
    "position": "center",
    "size": 280,
    "opacity": 30,
    "tintMode": "theme-accent",
    "customColor": "#ffffff",
    "offsetX": 0,
    "offsetY": 0,
    "margin": 48,
    "rotation": 0,
    "showShadow": False,
    "customImagePath": "",
    "customText": "OMARCHY",
    "textFont": "modern-sans",
    "renderedAscii": "",
    "primaryScreenOnly": False,
    "showLabel": True
}


def render_ascii_art(text: str, font: str) -> str:
    text = (text or "").strip()[:100]  # Cap input text length to prevent DoS
    if not text:
        return ""
    try:
        import pyfiglet
        f = pyfiglet.Figlet(font=font, width=2000)
        res = f.renderText(text)
        raw_lines = res.split("\n")
        # Strip outer empty vertical padding lines
        while raw_lines and not raw_lines[-1].strip():
            raw_lines.pop()
        while raw_lines and not raw_lines[0].strip():
            raw_lines.pop(0)
        if not raw_lines:
            return ""
        # Pad all lines to the exact same maximum line width to prevent misalignment
        max_len = max(len(l) for l in raw_lines)
        padded_lines = [l.ljust(max_len) for l in raw_lines]
        return "\n".join(padded_lines)
    except Exception:
        return text


def load_config() -> dict:
    STATE_DIR.mkdir(parents=True, exist_ok=True, mode=0o700)
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                merged = dict(DEFAULTS)
                merged.update(data)
                return merged
        except Exception:
            pass
    save_config(DEFAULTS)
    return dict(DEFAULTS)


def save_config(cfg: dict):
    STATE_DIR.mkdir(parents=True, exist_ok=True, mode=0o700)
    
    # Boundary and type sanitization
    preset_ids = [p["id"] for p in PRESETS]
    font_ids = [f["id"] for f in FONTS]
    
    if cfg.get("preset") not in preset_ids:
        cfg["preset"] = "omarchy"
    if cfg.get("position") not in POSITIONS:
        cfg["position"] = "center"
    if cfg.get("tintMode") not in TINT_MODES:
        cfg["tintMode"] = "theme-accent"
        
    try:
        cfg["size"] = max(32, min(1000, int(cfg.get("size", 280))))
        cfg["opacity"] = max(0, min(100, int(cfg.get("opacity", 30))))
        cfg["margin"] = max(0, min(500, int(cfg.get("margin", 48))))
        cfg["rotation"] = max(-180, min(180, int(cfg.get("rotation", 0))))
    except (ValueError, TypeError):
        pass

    font_id = cfg.get("textFont", "modern-sans")
    if font_id not in font_ids:
        font_id = "modern-sans"
        cfg["textFont"] = font_id

    ascii_ids = [f["id"] for f in FONTS if f["type"] == "ascii"]
    if font_id in ascii_ids:
        cfg["renderedAscii"] = render_ascii_art(cfg.get("customText", "OMARCHY"), font_id)
    else:
        cfg["renderedAscii"] = ""

    tmp = CONFIG_FILE.with_suffix(".tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(cfg, f, indent=2)
    os.chmod(tmp, 0o600)
    tmp.replace(CONFIG_FILE)


def browse_image():
    chosen = None
    dialog_launched = False

    # 1. Tkinter File Dialog (Desktop GUI File Selector)
    try:
        import tkinter as tk
        from tkinter import filedialog
        root = tk.Tk()
        root.withdraw()
        root.attributes("-topmost", True)
        initial = os.path.expanduser("~/Pictures")
        if not os.path.isdir(initial):
            initial = os.path.expanduser("~")
        chosen = filedialog.askopenfilename(
            title="Select Logo / Watermark Image (OmaStamp)",
            initialdir=initial,
            filetypes=[
                ("Image Files", "*.png *.svg *.jpg *.jpeg *.webp *.gif *.bmp"),
                ("SVG Vector", "*.svg"),
                ("PNG Images", "*.png"),
                ("JPEG Images", "*.jpg *.jpeg"),
                ("WebP Images", "*.webp"),
                ("All Files", "*.*")
            ]
        )
        dialog_launched = True
        root.destroy()
    except Exception:
        dialog_launched = False

    # 2. Omarchy Menu File Fallback (ONLY if Tkinter dialog failed to launch)
    if not dialog_launched and shutil.which("omarchy-menu-file"):
        try:
            search_dirs = [d for d in [os.path.expanduser("~/Pictures"), os.path.expanduser("~/Downloads"), os.path.expanduser("~/.config/omarchy")] if os.path.isdir(d)]
            if not search_dirs:
                search_dirs = [os.path.expanduser("~")]
            dirs_str = ":".join(search_dirs)
            res = subprocess.run(["omarchy-menu-file", "Select Logo / Watermark Image", dirs_str, "png svg jpg jpeg webp"], capture_output=True, text=True)
            if res.returncode == 0 and res.stdout.strip():
                chosen = res.stdout.strip()
            dialog_launched = True
        except Exception:
            pass

    # 3. Zenity / Kdialog fallback (ONLY if previous tools failed to launch)
    if not dialog_launched:
        if shutil.which("zenity"):
            try:
                res = subprocess.run(["zenity", "--file-selection", "--title=Select Logo / Watermark Image"], capture_output=True, text=True)
                if res.returncode == 0 and res.stdout.strip():
                    chosen = res.stdout.strip()
                dialog_launched = True
            except Exception:
                pass
        elif shutil.which("kdialog"):
            try:
                res = subprocess.run(["kdialog", "--getopenfilename", os.path.expanduser("~/Pictures")], capture_output=True, text=True)
                if res.returncode == 0 and res.stdout.strip():
                    chosen = res.stdout.strip()
                dialog_launched = True
            except Exception:
                pass

    if chosen and os.path.isfile(chosen):
        chosen_path = str(Path(chosen).resolve())
        cfg = load_config()
        cfg["mode"] = "image"
        cfg["customImagePath"] = chosen_path
        cfg["enabled"] = True
        save_config(cfg)
        print(f"✓ Selected custom image: {chosen_path}")
        return chosen_path

    return None


def main():
    parser = argparse.ArgumentParser(
        prog="omastamp",
        description="OmaStamp — Desktop Logo & Watermark Overlay for Omarchy"
    )
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # get / status
    subparsers.add_parser("get", help="Print active configuration as JSON")
    subparsers.add_parser("status", help="Print human-readable status summary")

    # toggles
    subparsers.add_parser("toggle", help="Toggle stamp on/off")
    subparsers.add_parser("on", help="Turn stamp overlay ON")
    subparsers.add_parser("enable", help="Turn stamp overlay ON")
    subparsers.add_parser("off", help="Turn stamp overlay OFF")
    subparsers.add_parser("disable", help="Turn stamp overlay OFF")

    # presets
    p_preset = subparsers.add_parser("set-preset", help="Set active preset logo")
    p_preset.add_argument("preset_id", choices=[p["id"] for p in PRESETS], help="Preset identifier")

    subparsers.add_parser("next-preset", help="Cycle to next preset logo")
    subparsers.add_parser("prev-preset", help="Cycle to previous preset logo")
    subparsers.add_parser("list-presets", help="List all available preset logos")

    # custom image
    p_img = subparsers.add_parser("set-image", help="Set custom image file path")
    p_img.add_argument("path", help="Path to image or SVG file")

    subparsers.add_parser("browse", help="Open graphical file dialog to select image")
    subparsers.add_parser("pick", help="Open graphical file dialog to select image")

    # custom text
    p_txt = subparsers.add_parser("set-text", help="Set custom text / watermark")
    p_txt.add_argument("text", help="Main watermark text string")
    p_txt.add_argument("--font", dest="font", choices=[f["id"] for f in FONTS], help="Typography or ASCII font style")

    p_font = subparsers.add_parser("set-font", help="Set watermark text font style")
    p_font.add_argument("font", choices=[f["id"] for f in FONTS], help="Font identifier")

    subparsers.add_parser("list-fonts", help="List all available text typography & ASCII fonts")

    # position
    p_pos = subparsers.add_parser("set-position", help="Set screen alignment position")
    p_pos.add_argument("position", choices=POSITIONS, help="Placement anchor")

    # size
    p_size = subparsers.add_parser("set-size", help="Set logo size in pixels")
    p_size.add_argument("size", type=int, help="Size in px (32-800)")

    # opacity
    p_op = subparsers.add_parser("set-opacity", help="Set opacity percentage (0-100)")
    p_op.add_argument("opacity", type=int, help="Opacity percentage (0-100)")

    # tint
    p_tint = subparsers.add_parser("set-tint", help="Set color tint mode")
    p_tint.add_argument("mode", choices=TINT_MODES, help="Tint mode")
    p_tint.add_argument("color", nargs="?", default=None, help="Optional custom hex color")

    # rotation
    p_rot = subparsers.add_parser("set-rotation", help="Set rotation angle in degrees")
    p_rot.add_argument("degrees", type=int, help="Degrees (-180 to 180)")

    # margin
    p_mar = subparsers.add_parser("set-margin", help="Set screen edge margin in pixels")
    p_mar.add_argument("margin", type=int, help="Margin in pixels (0-300)")

    # shadow
    p_shd = subparsers.add_parser("set-shadow", help="Toggle subtle drop shadow")
    p_shd.add_argument("enable", choices=["true", "false", "on", "off", "1", "0"], help="Enable shadow")

    # primary screen only
    p_pri = subparsers.add_parser("set-primary-only", help="Toggle primary monitor only")
    p_pri.add_argument("enable", choices=["true", "false", "on", "off", "1", "0"], help="Enable primary only")

    # reset
    subparsers.add_parser("reset", help="Reset all settings to defaults")

    args = parser.parse_args()

    if not args.command:
        # Default behavior with no arguments: show status
        args.command = "status"

    cfg = load_config()

    if args.command == "get":
        print(json.dumps(cfg, indent=2))
        return

    if args.command in ("browse", "pick"):
        browse_image()
        return

    if args.command == "status":
        state_str = "🟢 ACTIVE" if cfg.get("enabled") else "⚪ DISABLED"
        mode = cfg.get("mode", "preset")
        target = ""
        if mode == "preset":
            target = f"Preset '{cfg.get('preset')}'"
        elif mode == "image":
            target = f"Image '{os.path.basename(cfg.get('customImagePath', 'none'))}'"
        else:
            target = f"Text '{cfg.get('customText')}' (Font: {cfg.get('textFont', 'modern-sans')})"

        print("──────────────────────────────────────────")
        print(f" 🖃  OmaStamp — Desktop Logo Overlay")
        print("──────────────────────────────────────────")
        print(f" Status:    {state_str}")
        print(f" Mode:      {mode.upper()} ({target})")
        print(f" Position:  {cfg.get('position')}")
        print(f" Size:      {cfg.get('size')} px")
        print(f" Opacity:   {cfg.get('opacity')} %")
        print(f" Tint:      {cfg.get('tintMode')} ({cfg.get('customColor')})")
        print(f" Rotation:  {cfg.get('rotation')}°")
        print(f" Margin:    {cfg.get('margin')} px")
        print(f" Shadow:    {'Yes' if cfg.get('showShadow') else 'No'}")
        print(f" Display:   {'Primary Only' if cfg.get('primaryScreenOnly') else 'All Monitors'}")
        print("──────────────────────────────────────────")
        return

    if args.command == "list-presets":
        print("Available Preset Logos:")
        for p in PRESETS:
            cur = " (active)" if p["id"] == cfg.get("preset") else ""
            print(f"  • {p['id']:<14} : {p['name']:<18} — {p['desc']}{cur}")
        return

    if args.command == "list-fonts":
        print("Available Typography & ASCII Fonts:")
        for f in FONTS:
            cur = " (active)" if f["id"] == cfg.get("textFont") else ""
            print(f"  • [{f['type'].upper():<5}] {f['id']:<20} : {f['name']:<20} — {f['desc']}{cur}")
        return

    if args.command == "toggle":
        cfg["enabled"] = not cfg.get("enabled", True)
        save_config(cfg)
        state_str = "ENABLED" if cfg["enabled"] else "DISABLED"
        print(f"✓ OmaStamp is now {state_str}")
        return

    if args.command in ("on", "enable"):
        cfg["enabled"] = True
        save_config(cfg)
        print("✓ OmaStamp enabled")
        return

    if args.command in ("off", "disable"):
        cfg["enabled"] = False
        save_config(cfg)
        print("✓ OmaStamp disabled")
        return

    if args.command == "set-preset":
        cfg["mode"] = "preset"
        cfg["preset"] = args.preset_id
        save_config(cfg)
        print(f"✓ Active preset set to '{args.preset_id}'")
        return

    if args.command == "next-preset":
        cur_id = cfg.get("preset", "omarchy")
        ids = [p["id"] for p in PRESETS]
        try:
            idx = (ids.index(cur_id) + 1) % len(ids)
        except ValueError:
            idx = 0
        cfg["mode"] = "preset"
        cfg["preset"] = ids[idx]
        save_config(cfg)
        print(f"✓ Cycled to preset '{ids[idx]}'")
        return

    if args.command == "prev-preset":
        cur_id = cfg.get("preset", "omarchy")
        ids = [p["id"] for p in PRESETS]
        try:
            idx = (ids.index(cur_id) - 1 + len(ids)) % len(ids)
        except ValueError:
            idx = 0
        cfg["mode"] = "preset"
        cfg["preset"] = ids[idx]
        save_config(cfg)
        print(f"✓ Cycled to preset '{ids[idx]}'")
        return

    if args.command == "set-image":
        img_path = str(Path(args.path).expanduser().resolve())
        if not os.path.isfile(img_path):
            print(f"Error: File not found: {img_path}", file=sys.stderr)
            sys.exit(1)
        cfg["mode"] = "image"
        cfg["customImagePath"] = img_path
        save_config(cfg)
        print(f"✓ Custom image set to '{img_path}'")
        return

    if args.command == "set-text":
        cfg["mode"] = "text"
        cfg["customText"] = args.text
        if args.font:
            cfg["textFont"] = args.font
        save_config(cfg)
        print(f"✓ Custom text set to '{args.text}' (Font: {cfg.get('textFont', 'modern-sans')})")
        return

    if args.command == "set-font":
        cfg["mode"] = "text"
        cfg["textFont"] = args.font
        save_config(cfg)
        print(f"✓ Watermark font set to '{args.font}'")
        return

    if args.command == "set-position":
        cfg["position"] = args.position
        save_config(cfg)
        print(f"✓ Position set to '{args.position}'")
        return

    if args.command == "set-size":
        size = max(32, min(800, args.size))
        cfg["size"] = size
        save_config(cfg)
        print(f"✓ Size set to {size}px")
        return

    if args.command == "set-opacity":
        op = max(0, min(100, args.opacity))
        cfg["opacity"] = op
        save_config(cfg)
        print(f"✓ Opacity set to {op}%")
        return

    if args.command == "set-tint":
        cfg["tintMode"] = args.mode
        if args.color:
            cfg["customColor"] = args.color
        save_config(cfg)
        print(f"✓ Tint mode set to '{args.mode}'" + (f" ({args.color})" if args.color else ""))
        return

    if args.command == "set-rotation":
        rot = max(-180, min(180, args.degrees))
        cfg["rotation"] = rot
        save_config(cfg)
        print(f"✓ Rotation set to {rot}°")
        return

    if args.command == "set-margin":
        margin = max(0, min(300, args.margin))
        cfg["margin"] = margin
        save_config(cfg)
        print(f"✓ Margin set to {margin}px")
        return

    if args.command == "set-shadow":
        val = args.enable.lower() in ("true", "on", "1")
        cfg["showShadow"] = val
        save_config(cfg)
        print(f"✓ Drop shadow {'enabled' if val else 'disabled'}")
        return

    if args.command == "set-primary-only":
        val = args.enable.lower() in ("true", "on", "1")
        cfg["primaryScreenOnly"] = val
        save_config(cfg)
        print(f"✓ Primary screen only {'enabled' if val else 'disabled'}")
        return

    if args.command == "reset":
        save_config(DEFAULTS)
        print("✓ Reset all OmaStamp settings to defaults")
        return


if __name__ == "__main__":
    main()

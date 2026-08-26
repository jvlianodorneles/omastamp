#!/usr/bin/env bash
# ==============================================================================
# OmaStamp Image Browser
# Uses Omarchy's native image selector / file picker and applies to OmaStamp
# ==============================================================================

STATE_DIR="${HOME}/.local/state/omarchy/omastamp"
CONFIG_FILE="${STATE_DIR}/config.json"
mkdir -p "${STATE_DIR}"

CHOSEN=""

# 1. Try omarchy-menu-images with common graphic directories if available
SEARCH_DIRS=()
for d in "$HOME/Pictures" "$HOME/Downloads" "$HOME/.config/omarchy" "$HOME"; do
  if [ -d "$d" ]; then
    SEARCH_DIRS+=("$d")
  fi
done

if command -v omarchy-menu-file >/dev/null 2>&1; then
  DIRS_JOINED=$(IFS=:; echo "${SEARCH_DIRS[*]}")
  CHOSEN=$(omarchy-menu-file "Select Logo / Watermark Image" "$DIRS_JOINED" "png svg jpg jpeg webp" 2>/dev/null || true)
fi

# Fallback to Python Tkinter dialog if omarchy-menu-file returned nothing or failed
if [ -z "$CHOSEN" ] && python3 -c "import tkinter, sys; sys.exit(0)" 2>/dev/null; then
  CHOSEN=$(python3 -c "
import os, sys
import tkinter as tk
from tkinter import filedialog
try:
    root = tk.Tk()
    root.withdraw()
    root.attributes('-topmost', True)
    initial = os.path.expanduser('~/Pictures')
    if not os.path.isdir(initial):
        initial = os.path.expanduser('~')
    path = filedialog.askopenfilename(
        title='Select Logo / Watermark Image',
        initialdir=initial,
        filetypes=[
            ('Image Files', '*.png *.svg *.jpg *.jpeg *.webp *.gif *.bmp'),
            ('SVG Vector', '*.svg'),
            ('PNG Image', '*.png'),
            ('All Files', '*.*')
        ]
    )
    if path:
        print(path)
except Exception:
    pass
" 2>/dev/null || true)
fi

if [ -n "$CHOSEN" ] && [ -f "$CHOSEN" ]; then
  CHOSEN_PATH=$(realpath "$CHOSEN")
  python3 -c '
import json, os, sys, tempfile

cfg_path = sys.argv[1]
chosen_path = sys.argv[2]

data = {}
if os.path.exists(cfg_path) and not os.path.islink(cfg_path):
    try:
        if os.path.getsize(cfg_path) <= 65536:
            with open(cfg_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                if not isinstance(data, dict):
                    data = {}
    except Exception:
        data = {}

data["mode"] = "image"
data["customImagePath"] = chosen_path
data["enabled"] = True

dir_name = os.path.dirname(cfg_path)
os.makedirs(dir_name, mode=0o700, exist_ok=True)
tmp_file = tempfile.NamedTemporaryFile(
    mode="w",
    dir=dir_name,
    prefix="config-",
    suffix=".tmp",
    delete=False,
    encoding="utf-8"
)
tmp_path = tmp_file.name
try:
    json.dump(data, tmp_file, indent=2)
    tmp_file.write("\n")
    tmp_file.flush()
    os.fsync(tmp_file.fileno())
    tmp_file.close()
    os.chmod(tmp_path, 0o600)
    os.replace(tmp_path, cfg_path)
except Exception:
    if os.path.exists(tmp_path):
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
    raise

print("✓ Selected image:", chosen_path)
' "$CONFIG_FILE" "$CHOSEN_PATH"
  echo "$CHOSEN_PATH"
  exit 0
fi

exit 1

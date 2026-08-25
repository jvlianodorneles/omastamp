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
  python3 -c "
import json, os
cfg_path = '$CONFIG_FILE'
try:
    with open(cfg_path, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}

data['mode'] = 'image'
data['customImagePath'] = '$CHOSEN_PATH'
data['enabled'] = True

tmp = cfg_path + '.tmp'
with open(tmp, 'w') as f:
    json.dump(data, f, indent=2)
os.replace(tmp, cfg_path)
print('✓ Selected image:', '$CHOSEN_PATH')
"
  echo "$CHOSEN_PATH"
  exit 0
fi

exit 1

#!/usr/bin/env bash
# ==============================================================================
# OmaStamp Image File Picker
# Opens a file selection dialog using the best available tool on the system
# ==============================================================================

# 1. Try Zenity if available
if command -v zenity >/dev/null 2>&1; then
  zenity --file-selection \
    --title="Select Logo / Watermark Image" \
    --file-filter="Images (*.png *.svg *.jpg *.jpeg *.webp) | *.png *.svg *.jpg *.jpeg *.webp *.PNG *.SVG *.JPG *.JPEG *.WEBP" \
    2>/dev/null && exit 0
fi

# 2. Try Kdialog if available
if command -v kdialog >/dev/null 2>&1; then
  kdialog --title "Select Logo / Watermark Image" \
    --getopenfilename "$HOME/Pictures" "*.png *.svg *.jpg *.jpeg *.webp|Image files" \
    2>/dev/null && exit 0
fi

# 3. Try Python Tkinter GUI File Dialog
if python3 -c "import tkinter, sys; sys.exit(0)" 2>/dev/null; then
  RESULT=$(python3 -c "
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
    file_path = filedialog.askopenfilename(
        title='Select Logo / Watermark Image',
        initialdir=initial,
        filetypes=[
            ('Image Files', '*.png *.svg *.jpg *.jpeg *.webp *.gif *.bmp'),
            ('SVG Vector', '*.svg'),
            ('PNG Images', '*.png'),
            ('JPEG Images', '*.jpg *.jpeg'),
            ('All Files', '*.*')
        ]
    )
    if file_path:
        print(file_path)
except Exception:
    sys.exit(1)
" 2>/dev/null)

  if [ -n "$RESULT" ] && [ -f "$RESULT" ]; then
    echo "$RESULT"
    exit 0
  fi
fi

# 4. Fallback to native Omarchy file menu
if command -v omarchy-menu-file >/dev/null 2>&1; then
  SEARCH_DIRS="$HOME/Pictures:$HOME/Downloads:$HOME"
  omarchy-menu-file "Select Logo / Watermark Image" "$SEARCH_DIRS" "png svg jpg jpeg webp" 2>/dev/null && exit 0
fi

exit 1

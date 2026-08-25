#!/usr/bin/env bash
# ==============================================================================
# OmaStamp — Uninstaller Script for Omarchy
# ==============================================================================

set -e

BIN_DIR="${HOME}/.local/bin"
STATE_DIR="${HOME}/.local/state/omarchy/omastamp"
SHELL_CONFIG="${HOME}/.config/omarchy/shell.json"
OMARCHY_PLUGIN_DIR="${HOME}/.config/omarchy/plugins/dorneles.omastamp"

echo "🗑️  Uninstalling OmaStamp..."

# 1. Remove CLI binary
if [ -f "${BIN_DIR}/omastamp" ]; then
  rm -f "${BIN_DIR}/omastamp"
  echo "✓ Removed ${BIN_DIR}/omastamp"
fi

# 2. Remove Plugin Directory
if [ -d "${OMARCHY_PLUGIN_DIR}" ]; then
  rm -rf "${OMARCHY_PLUGIN_DIR}"
  echo "✓ Removed plugin directory ${OMARCHY_PLUGIN_DIR}"
fi

# 3. Unregister from shell.json
if [ -f "${SHELL_CONFIG}" ]; then
  OMASTAMP_CONFIG_PATH="${SHELL_CONFIG}" python3 -c "
import json, os
config_path = os.environ.get('OMASTAMP_CONFIG_PATH')
try:
    with open(config_path, 'r') as f:
        data = json.load(f)

    # Remove from bar layout
    bar_layout = data.get('bar', {}).get('layout', {})
    for sec in ['left', 'center', 'right']:
        if sec in bar_layout and isinstance(bar_layout[sec], list):
            bar_layout[sec] = [item for item in bar_layout[sec] if (item.get('id') if isinstance(item, dict) else item) != 'dorneles.omastamp']

    # Remove from plugins
    if 'plugins' in data and isinstance(data['plugins'], list):
        data['plugins'] = [item for item in data['plugins'] if (item.get('id') if isinstance(item, dict) else item) != 'dorneles.omastamp']

    with open(config_path, 'w') as f:
        json.dump(data, f, indent=2)
    print('✓ Unregistered dorneles.omastamp from shell.json')
except Exception as e:
    print('Note: Could not update shell.json:', e)
"
fi

# 4. Rescan plugins
if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
fi

echo "✨ OmaStamp uninstalled successfully."

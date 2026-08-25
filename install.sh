#!/usr/bin/env bash
# ==============================================================================
# OmaStamp — Installer Script for Omarchy
# Desktop Logo & Watermark Overlay Plugin
# (https://github.com/jvlianodorneles/omastamp)
# ==============================================================================

set -e

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
STATE_DIR="${HOME}/.local/state/omarchy/omastamp"
SHELL_CONFIG="${HOME}/.config/omarchy/shell.json"
OMARCHY_PLUGIN_DIR="${HOME}/.config/omarchy/plugins/dorneles.omastamp"

echo "🖃  Installing OmaStamp (Desktop Logo & Watermark Overlay)..."

# 1. Install CLI Tool
mkdir -p "${BIN_DIR}"
install -Dm755 "${SOURCE_DIR}/scripts/omastamp-ctl.py" "${BIN_DIR}/omastamp"
echo "✓ Installed CLI tool to ${BIN_DIR}/omastamp"

# 2. Install Omarchy Quickshell Plugin
mkdir -p "${OMARCHY_PLUGIN_DIR}/assets/logos"
mkdir -p "${OMARCHY_PLUGIN_DIR}/scripts"
mkdir -p "${STATE_DIR}"

cp -r "${SOURCE_DIR}/manifest.json" \
      "${SOURCE_DIR}/BarWidget.qml" \
      "${SOURCE_DIR}/Overlay.qml" \
      "${SOURCE_DIR}/Panel.qml" \
      "${OMARCHY_PLUGIN_DIR}/"

cp -r "${SOURCE_DIR}/assets" "${OMARCHY_PLUGIN_DIR}/"
cp -r "${SOURCE_DIR}/scripts" "${OMARCHY_PLUGIN_DIR}/"

echo "✓ Installed Omarchy Quickshell Plugin to ${OMARCHY_PLUGIN_DIR}"

# 3. Initialize default config if not present
if [ ! -f "${STATE_DIR}/config.json" ]; then
  python3 "${SOURCE_DIR}/scripts/omastamp-ctl.py" reset >/dev/null 2>&1 || true
  echo "✓ Initialized state at ${STATE_DIR}/config.json"
fi

# 4. Register in Omarchy shell.json
if [ -f "${SHELL_CONFIG}" ]; then
  OMASTAMP_CONFIG_PATH="${SHELL_CONFIG}" python3 -c "
import json, os
config_path = os.environ.get('OMASTAMP_CONFIG_PATH')
try:
    with open(config_path, 'r') as f:
        data = json.load(f)

    # Register bar widget
    bar_layout = data.setdefault('bar', {}).setdefault('layout', {})
    right_list = bar_layout.setdefault('right', [])
    ids = [item.get('id') if isinstance(item, dict) else item for item in right_list]
    if 'dorneles.omastamp' not in ids:
        right_list.insert(0, {'id': 'dorneles.omastamp'})
        print('✓ Registered dorneles.omastamp in Omarchy bar widget layout')

    # Register overlay plugin in plugins array
    plugins_list = data.setdefault('plugins', [])
    plugin_ids = [item.get('id') if isinstance(item, dict) else item for item in plugins_list]
    if 'dorneles.omastamp' not in plugin_ids:
        plugins_list.append({'id': 'dorneles.omastamp'})
        print('✓ Registered dorneles.omastamp in Omarchy plugins list')

    with open(config_path, 'w') as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print('Note: Could not automatically update shell.json:', e)
"
fi

# 5. Hot reload shell if running
if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  echo "✓ Omarchy shell rescanned plugins"
fi

echo ""
echo "✨ Installation complete!"
echo "• Status Bar Widget: Active on your Omarchy bar"
echo "• Desktop Overlay: Stamped over your background"
echo "• CLI Tool: Try 'omastamp status', 'omastamp list-presets', or 'omastamp toggle'"

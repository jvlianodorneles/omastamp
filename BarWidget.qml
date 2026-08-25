import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "dorneles.omastamp"

  readonly property bool showLabelSetting: setting("showLabel", true)
  readonly property string stateFilePath: Quickshell.env("HOME") + "/.local/state/omarchy/omastamp/config.json"

  // Live state
  property bool stampEnabled: true
  property string currentMode: "preset"
  property string currentPreset: "omarchy"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  FileView {
    id: configFile
    path: root.stateFilePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var raw = text()
        if (raw && raw.trim().length > 0) {
          var cfg = JSON.parse(raw)
          if (cfg) {
            if (cfg.enabled !== undefined) root.stampEnabled = Boolean(cfg.enabled)
            if (cfg.mode !== undefined) root.currentMode = String(cfg.mode)
            if (cfg.preset !== undefined) root.currentPreset = String(cfg.preset)
          }
        }
      } catch (e) {
      }
    }
  }

  function toggleStamp() {
    root.stampEnabled = !root.stampEnabled
    try {
      var raw = configFile.text() || "{}"
      var cfg = JSON.parse(raw)
      cfg.enabled = root.stampEnabled
      configFile.setText(JSON.stringify(cfg, null, 2) + "\n")
    } catch (e) {
    }
  }

  function cyclePreset() {
    var presets = ["omarchy", "omarchy-text", "arch", "hyprland", "tux", "cyber-hex", "retro-globe", "arcade-ghost", "terminal", "minimal-star"]
    var idx = presets.indexOf(root.currentPreset)
    var next = presets[(idx + 1) % presets.length]
    root.currentPreset = next
    root.currentMode = "preset"
    try {
      var raw = configFile.text() || "{}"
      var cfg = JSON.parse(raw)
      cfg.mode = "preset"
      cfg.preset = next
      configFile.setText(JSON.stringify(cfg, null, 2) + "\n")
    } catch (e) {
    }
  }

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // Loader for popup panel
  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  // IPC handler for keybindings and shell commands
  IpcHandler {
    target: "dorneles.omastamp"

    function toggle(): void { root.togglePanel() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggleState(): void { root.toggleStamp() }
    function cycle(): void { root.cyclePreset() }
  }

  // Status Bar Button with Stamp icon (\udb83\ude62 = 󰹢)
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: (root.showLabelSetting && button.bar && !button.bar.vertical) ? "\udb83\ude62 Stamp" : "\udb83\ude62"
    active: root.opened
    fontSize: Style.bar.iconFont
    dimmed: !root.stampEnabled
    tooltipText: "OmaStamp (Desktop Logo Overlay)\n• Left-click: Open Studio\n• Right-click: Toggle On/Off\n• Middle-click: Cycle Logo"

    onPressed: function(btn) {
      if (btn === Qt.RightButton) {
        root.toggleStamp()
      } else if (btn === Qt.MiddleButton) {
        root.cyclePreset()
      } else {
        root.togglePanel()
      }
    }
  }
}

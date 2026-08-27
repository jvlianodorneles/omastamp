import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "dorneles.omastamp"

  readonly property string stateDirPath: Quickshell.env("HOME") + "/.local/state/omarchy/omastamp"

  // Live state
  property bool stampEnabled: true
  property string currentMode: "preset"
  property string currentPreset: "omarchy"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function applyConfig(cfg) {
    if (!cfg || typeof cfg !== "object") return
    if (cfg.enabled !== undefined) root.stampEnabled = Boolean(cfg.enabled)
    if (cfg.mode !== undefined) root.currentMode = String(cfg.mode)
    if (cfg.preset !== undefined) root.currentPreset = String(cfg.preset)
  }

  Process {
    id: configLoader
    command: ["bash", "-c", "command -v omastamp >/dev/null 2>&1 && exec omastamp get || exec python3 \"$HOME/.config/omarchy/plugins/dorneles.omastamp/scripts/omastamp-ctl.py\" get"]
    running: false
    stdout: SplitParser {
      onRead: function(line) {
        if (!line || line.length > 65536) return
        try {
          var cfg = JSON.parse(line)
          if (cfg && typeof cfg === "object") {
            root.applyConfig(cfg)
          }
        } catch (e) {
        }
      }
    }
  }

  function reloadConfig() {
    if (!configLoader.running) {
      configLoader.running = true
    }
  }

  FileView {
    id: stateDirWatcher
    path: root.stateDirPath
    watchChanges: true
    printErrors: false
    onFileChanged: root.reloadConfig()
  }

  Component.onCompleted: root.reloadConfig()

  function toggleStamp() {
    Util.execDetached("omastamp toggle")
  }

  function cyclePreset() {
    Util.execDetached("omastamp next-preset")
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

  // Status Bar Button with Postal Stamp Vector Icon
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: " "
    labelVisible: false
    hasVisualContent: true
    active: root.opened
    dimmed: !root.stampEnabled
    tooltipText: "OmaStamp (Desktop Logo Overlay)\n• Left-click: Open Studio\n• Right-click: Toggle On/Off\n• Middle-click: Cycle Logo"

    Item {
      anchors.centerIn: parent
      width: Style.space(16)
      height: Style.space(16)

      Image {
        id: stampIconImg
        anchors.fill: parent
        source: Qt.resolvedUrl("assets/icon.svg")
        sourceSize: Qt.size(32, 32)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true

        layer.enabled: true
        layer.effect: MultiEffect {
          colorization: 1.0
          colorizationColor: root.opened ? (button.useActiveColor ? button.activeColor : button.foreground) : (root.stampEnabled ? button.foreground : Util.alpha(button.foreground, 0.45))
        }
      }
    }

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

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

  readonly property bool showLabelSetting: setting("showLabel", true)

  readonly property string stateFilePath: Quickshell.env("HOME") + "/.local/state/omarchy/omastamp/config.json"

  // Live state
  property bool stampEnabled: true
  property string currentMode: "preset"
  property string currentPreset: "omarchy"

  readonly property bool opened: popupCard.open

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
    popupCard.open = true
  }

  function close() {
    popupCard.open = false
  }

  function toggle() {
    popupCard.open = !popupCard.open
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // -------------------------------------------------------------
  // Status Bar Button
  // -------------------------------------------------------------
  WidgetButton {
    id: button
    bar: root.bar
    selected: popupCard.open
    tooltipText: "OmaStamp Studio — Desktop Logo Overlay\nLeft-click: Open Studio\nRight-click: Toggle On/Off\nMiddle-click: Cycle Logo"

    onClicked: root.toggle()
    onRightClicked: root.toggleStamp()
    onMiddleClicked: root.cyclePreset()

    RowLayout {
      anchors.centerIn: parent
      spacing: Style.space(6)

      Item {
        width: Style.space(16)
        height: Style.space(16)
        Layout.alignment: Qt.AlignVCenter

        Image {
          anchors.fill: parent
          source: Qt.resolvedUrl("assets/icon.svg")
          sourceSize: Qt.size(16, 16)
          fillMode: Image.PreserveAspectFit
          layer.enabled: true
          layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: root.stampEnabled ? (button.bar ? button.bar.accent : Color.accent) : (button.bar ? Qt.darker(button.bar.foreground, 1.6) : Qt.darker(Color.foreground, 1.6))
          }
        }

        // Active indicator dot
        Rectangle {
          width: 5
          height: 5
          radius: 2.5
          anchors.bottom: parent.bottom
          anchors.right: parent.right
          color: root.stampEnabled ? Color.accent : "transparent"
          visible: root.stampEnabled
        }
      }

      Text {
        visible: root.showLabelSetting && button.bar && (button.bar.position === "top" || button.bar.position === "bottom")
        text: "Stamp"
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        color: root.stampEnabled ? (button.bar ? button.bar.foreground : Color.foreground) : Qt.darker(Color.foreground, 1.4)
        Layout.alignment: Qt.AlignVCenter
      }
    }
  }

  // -------------------------------------------------------------
  // Popup Studio Card
  // -------------------------------------------------------------
  PopupCard {
    id: popupCard
    anchorItem: button
    bar: root.bar
    owner: root
    contentWidth: Style.space(380)
    contentHeight: panelItem.implicitHeight

    Panel {
      id: panelItem
      bar: root.bar
      settings: root.settings
      hostWidget: root
    }
  }
}

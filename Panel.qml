import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "dorneles.omastamp"
  ipcTarget: "dorneles.omastamp"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string stateFilePath: Quickshell.env("HOME") + "/.local/state/omarchy/omastamp/config.json"

  // Live configuration state
  property bool stampEnabled: true
  property string mode: "preset"
  property string presetId: "omarchy"
  property string position: "center"
  property int stampSize: 280
  property int stampOpacity: 30
  property string tintMode: "theme-accent"
  property string customColor: "#ffffff"
  property int offsetX: 0
  property int offsetY: 0
  property int margin: 48
  property int rotationAngle: 0
  property bool showShadow: false
  property string customImagePath: ""
  property string customText: "OMARCHY"
  property string customSubtext: ""
  property bool primaryScreenOnly: false

  readonly property var presetsList: [
    { id: "omarchy", name: "Omarchy", icon: "assets/logos/omarchy.svg" },
    { id: "omarchy-text", name: "Omarchy Typo", icon: "assets/logos/omarchy-text.svg" },
    { id: "arch", name: "Arch Linux", icon: "assets/logos/arch.svg" },
    { id: "hyprland", name: "Hyprland", icon: "assets/logos/hyprland.svg" },
    { id: "tux", name: "Tux Linux", icon: "assets/logos/tux.svg" },
    { id: "cyber-hex", name: "Cyber Hex", icon: "assets/logos/cyber-hex.svg" },
    { id: "retro-globe", name: "80s Globe", icon: "assets/logos/retro-globe.svg" },
    { id: "arcade-ghost", name: "Arcade Ghost", icon: "assets/logos/arcade-ghost.svg" },
    { id: "terminal", name: "Terminal", icon: "assets/logos/terminal.svg" },
    { id: "minimal-star", name: "Minimal Star", icon: "assets/logos/minimal-star.svg" }
  ]

  readonly property var positionsList: [
    { id: "top-left", label: "↖", name: "Top Left" },
    { id: "top-center", label: "↑", name: "Top Center" },
    { id: "top-right", label: "↗", name: "Top Right" },
    { id: "center-left", label: "←", name: "Center Left" },
    { id: "center", label: "•", name: "Center" },
    { id: "center-right", label: "→", name: "Center Right" },
    { id: "bottom-left", label: "↙", name: "Bottom Left" },
    { id: "bottom-center", label: "↓", name: "Bottom Center" },
    { id: "bottom-right", label: "↘", name: "Bottom Right" }
  ]

  readonly property var tintModesList: [
    { id: "theme-accent", label: "Accent" },
    { id: "theme-fg", label: "Text" },
    { id: "original", label: "Original" },
    { id: "white", label: "White" },
    { id: "black", label: "Black" },
    { id: "custom", label: "Custom" }
  ]

  // File watcher for real-time state synchronization
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
            if (cfg.mode !== undefined) root.mode = String(cfg.mode)
            if (cfg.preset !== undefined) root.presetId = String(cfg.preset)
            if (cfg.position !== undefined) root.position = String(cfg.position)
            if (cfg.size !== undefined) root.stampSize = Number(cfg.size)
            if (cfg.opacity !== undefined) root.stampOpacity = Number(cfg.opacity)
            if (cfg.tintMode !== undefined) root.tintMode = String(cfg.tintMode)
            if (cfg.customColor !== undefined) root.customColor = String(cfg.customColor)
            if (cfg.offsetX !== undefined) root.offsetX = Number(cfg.offsetX)
            if (cfg.offsetY !== undefined) root.offsetY = Number(cfg.offsetY)
            if (cfg.margin !== undefined) root.margin = Number(cfg.margin)
            if (cfg.rotation !== undefined) root.rotationAngle = Number(cfg.rotation)
            if (cfg.showShadow !== undefined) root.showShadow = Boolean(cfg.showShadow)
            if (cfg.customImagePath !== undefined) root.customImagePath = String(cfg.customImagePath)
            if (cfg.customText !== undefined) root.customText = String(cfg.customText)
            if (cfg.customSubtext !== undefined) root.customSubtext = String(cfg.customSubtext)
            if (cfg.primaryScreenOnly !== undefined) root.primaryScreenOnly = Boolean(cfg.primaryScreenOnly)
          }
        }
      } catch (e) {
      }
    }
  }

  function saveConfig() {
    var payload = {
      "enabled": root.stampEnabled,
      "mode": root.mode,
      "preset": root.presetId,
      "position": root.position,
      "size": root.stampSize,
      "opacity": root.stampOpacity,
      "tintMode": root.tintMode,
      "customColor": root.customColor,
      "offsetX": root.offsetX,
      "offsetY": root.offsetY,
      "margin": root.margin,
      "rotation": root.rotationAngle,
      "showShadow": root.showShadow,
      "customImagePath": root.customImagePath,
      "customText": root.customText,
      "customSubtext": root.customSubtext,
      "primaryScreenOnly": root.primaryScreenOnly
    }
    configFile.setText(JSON.stringify(payload, null, 2) + "\n")
  }

  function resetDefaults() {
    root.stampEnabled = true
    root.mode = "preset"
    root.presetId = "omarchy"
    root.position = "center"
    root.stampSize = 280
    root.stampOpacity = 30
    root.tintMode = "theme-accent"
    root.customColor = "#ffffff"
    root.offsetX = 0
    root.offsetY = 0
    root.margin = 48
    root.rotationAngle = 0
    root.showShadow = false
    root.customImagePath = ""
    root.customText = "OMARCHY"
    root.customSubtext = ""
    root.primaryScreenOnly = false
    saveConfig()
  }

  function open() {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function") {
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    }
    return false
  }

  function browseImage() {
    root.close()
    Quickshell.execDetached(["omastamp", "browse"])
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem || (hostWidget ? hostWidget : null)
    owner: root.barIdentity
    bar: root.bar || (hostWidget ? hostWidget.bar : null)
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight)

    PanelKeyCatcher {
      anchors.fill: parent

      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      ColumnLayout {
        id: panelColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        // -------------------------------------------------------------
        // Header (PanelHero)
        // -------------------------------------------------------------
        PanelHero {
          Layout.fillWidth: true
          title: "omastamp"
          meta: "DESKTOP LOGO OVERLAY"
          foreground: root.foreground
          fontFamily: root.fontFamily

          iconComponent: Component {
            Text {
              text: "󰹢"
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              color: root.stampEnabled ? Color.accent : Qt.darker(Color.foreground, 1.4)
            }
          }

          trailingControl: Component {
            Row {
              spacing: Style.space(8)

              ToggleSwitch {
                checked: root.stampEnabled
                onToggled: {
                  root.stampEnabled = !root.stampEnabled
                  root.saveConfig()
                }
              }

              Button {
                iconText: "󰅖"
                tooltipText: "Close (Esc)"
                fontSize: Style.font.body
                onClicked: root.close()
              }
            }
          }
        }

        PanelSeparator {
          Layout.fillWidth: true
        }

        // -------------------------------------------------------------
        // Mode Switcher (Presets / Custom Image / Text)
        // -------------------------------------------------------------
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(4)

          Button {
            Layout.fillWidth: true
            text: "Preset Logos"
            selected: root.mode === "preset"
            bordered: true
            onClicked: {
              root.mode = "preset"
              root.saveConfig()
            }
          }

          Button {
            Layout.fillWidth: true
            text: "Custom Image"
            selected: root.mode === "image"
            bordered: true
            onClicked: {
              root.mode = "image"
              root.saveConfig()
            }
          }

          Button {
            Layout.fillWidth: true
            text: "Watermark Text"
            selected: root.mode === "text"
            bordered: true
            onClicked: {
              root.mode = "text"
              root.saveConfig()
            }
          }
        }

        // -------------------------------------------------------------
        // Content 1: Preset Logos Grid
        // -------------------------------------------------------------
        ColumnLayout {
          Layout.fillWidth: true
          visible: root.mode === "preset"
          spacing: Style.space(6)

          GridLayout {
            Layout.fillWidth: true
            columns: 5
            rowSpacing: Style.space(6)
            columnSpacing: Style.space(6)

            Repeater {
              model: root.presetsList
              delegate: Rectangle {
                id: presetCard
                required property var modelData
                required property int index

                Layout.fillWidth: true
                height: Style.space(56)
                radius: Style.cornerRadius
                color: (root.presetId === modelData.id)
                  ? Util.alpha(Color.accent, 0.2)
                  : (presetMouse.containsMouse ? Util.alpha(Color.foreground, 0.08) : Util.alpha(Color.popups.background, 0.6))
                border.color: (root.presetId === modelData.id) ? Color.accent : Util.alpha(Color.popups.border, 0.4)
                border.width: (root.presetId === modelData.id) ? 2 : 1

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: Style.space(2)

                  Image {
                    Layout.alignment: Qt.AlignHCenter
                    width: Style.space(24)
                    height: Style.space(24)
                    source: Qt.resolvedUrl(modelData.icon)
                    sourceSize: Qt.size(24, 24)
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: MultiEffect {
                      colorization: 1.0
                      colorizationColor: (root.presetId === modelData.id) ? Color.accent : Color.foreground
                    }
                  }

                  Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.name
                    font.family: Style.fontRegular ? Style.fontRegular.family : "sans-serif"
                    font.pixelSize: 9
                    color: (root.presetId === modelData.id) ? Color.accent : Color.foreground
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: presetMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.presetId = modelData.id
                    root.mode = "preset"
                    root.saveConfig()
                  }
                }
              }
            }
          }
        }

        // -------------------------------------------------------------
        // Content 2: Custom Image Picker
        // -------------------------------------------------------------
        ColumnLayout {
          Layout.fillWidth: true
          visible: root.mode === "image"
          spacing: Style.space(6)

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

            TextField {
              id: customPathInput
              Layout.fillWidth: true
              text: root.customImagePath
              placeholderText: "Path to SVG, PNG, JPG image..."
              onEditingFinished: {
                root.customImagePath = text.trim()
                root.saveConfig()
              }
            }

            Button {
              text: "Browse..."
              bordered: true
              onClicked: root.browseImage()
            }
          }

          // Thumbnail Preview Box
          Rectangle {
            Layout.fillWidth: true
            height: Style.space(60)
            radius: Style.cornerRadius
            color: Util.alpha(Color.popups.background, 0.5)
            border.color: Util.alpha(Color.popups.border, 0.4)
            border.width: 1

            Image {
              anchors.centerIn: parent
              height: Style.space(48)
              width: Style.space(80)
              fillMode: Image.PreserveAspectFit
              source: root.customImagePath ? Util.fileUrl(root.customImagePath) : ""
              visible: root.customImagePath !== ""
              layer.enabled: root.tintMode !== "original"
              layer.effect: MultiEffect {
                colorization: (root.tintMode !== "original") ? 1.0 : 0.0
                colorizationColor: (root.tintMode === "theme-accent") ? Color.accent : ((root.tintMode === "theme-fg") ? Color.foreground : (root.customColor || "#ffffff"))
              }
            }

            Text {
              anchors.centerIn: parent
              visible: !root.customImagePath
              text: "No custom image selected"
              font.family: Style.fontRegular ? Style.fontRegular.family : "sans-serif"
              font.pixelSize: 11
              color: Qt.darker(Color.foreground, 1.5)
            }
          }
        }

        // -------------------------------------------------------------
        // Content 3: Watermark Text Inputs
        // -------------------------------------------------------------
        ColumnLayout {
          Layout.fillWidth: true
          visible: root.mode === "text"
          spacing: Style.space(6)

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

            ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.space(2)

              Text {
                text: "Main Title / Monogram:"
                font.pixelSize: 10
                color: Color.foreground
              }

              TextField {
                Layout.fillWidth: true
                text: root.customText
                placeholderText: "e.g. OMARCHY"
                onEditingFinished: {
                  root.customText = text.trim()
                  root.saveConfig()
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.space(2)

              Text {
                text: "Subtext / Slogan:"
                font.pixelSize: 10
                color: Color.foreground
              }

              TextField {
                Layout.fillWidth: true
                text: root.customSubtext
                placeholderText: "e.g. ARCH LINUX"
                onEditingFinished: {
                  root.customSubtext = text.trim()
                  root.saveConfig()
                }
              }
            }
          }
        }

        // -------------------------------------------------------------
        // Alignment Matrix & Color Tint Rows
        // -------------------------------------------------------------
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(12)

          // 3x3 Position Grid
          ColumnLayout {
            spacing: Style.space(4)

            Text {
              text: "Screen Position:"
              font.family: Style.fontRegular ? Style.fontRegular.family : "sans-serif"
              font.pixelSize: 11
              color: Color.foreground
            }

            GridLayout {
              columns: 3
              rowSpacing: Style.space(4)
              columnSpacing: Style.space(4)

              Repeater {
                model: root.positionsList
                delegate: Rectangle {
                  id: posBox
                  required property var modelData

                  width: Style.space(34)
                  height: Style.space(28)
                  radius: Style.cornerRadius
                  color: (root.position === modelData.id)
                    ? Color.accent
                    : (posMouse.containsMouse ? Util.alpha(Color.foreground, 0.12) : Util.alpha(Color.popups.background, 0.7))
                  border.color: (root.position === modelData.id) ? Color.accent : Util.alpha(Color.popups.border, 0.4)
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    font.family: Style.fontBold ? Style.fontBold.family : "sans-serif"
                    font.pixelSize: 14
                    font.bold: true
                    color: (root.position === modelData.id) ? Color.background : Color.foreground
                  }

                  MouseArea {
                    id: posMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      root.position = modelData.id
                      root.saveConfig()
                    }
                  }
                }
              }
            }
          }

          // Color Tint Mode Selection
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(4)

            Text {
              text: "Color Tint Palette:"
              font.family: Style.fontRegular ? Style.fontRegular.family : "sans-serif"
              font.pixelSize: 11
              color: Color.foreground
            }

            GridLayout {
              Layout.fillWidth: true
              columns: 3
              rowSpacing: Style.space(4)
              columnSpacing: Style.space(4)

              Repeater {
                model: root.tintModesList
                delegate: Button {
                  required property var modelData
                  Layout.fillWidth: true
                  text: modelData.label
                  selected: root.tintMode === modelData.id
                  bordered: true
                  onClicked: {
                    root.tintMode = modelData.id
                    root.saveConfig()
                  }
                }
              }
            }

            // Custom Hex Field if selected
            RowLayout {
              Layout.fillWidth: true
              visible: root.tintMode === "custom"
              spacing: Style.space(4)

              Rectangle {
                width: Style.space(22)
                height: Style.space(22)
                radius: Style.space(4)
                color: (root.customColor && root.customColor.length > 0) ? root.customColor : "#ffffff"
                border.color: Util.alpha(Color.popups.border, 0.8)
                border.width: 1
              }

              TextField {
                Layout.fillWidth: true
                text: root.customColor
                placeholderText: "#ffffff"
                onEditingFinished: {
                  root.customColor = text.trim()
                  root.saveConfig()
                }
              }
            }
          }
        }

        // -------------------------------------------------------------
        // Sliders: Size & Opacity
        // -------------------------------------------------------------
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          // Size Slider
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            Text {
              text: "Size:"
              font.pixelSize: 11
              color: Color.foreground
              Layout.preferredWidth: Style.space(55)
            }

            PanelSlider {
              Layout.fillWidth: true
              minimum: 48
              maximum: 720
              step: 8
              integer: true
              value: root.stampSize
              onMoved: function(val) {
                root.stampSize = Math.round(val)
              }
              onReleased: function(val) {
                root.stampSize = Math.round(val)
                root.saveConfig()
              }
            }

            Text {
              text: root.stampSize + "px"
              font.pixelSize: 11
              font.bold: true
              color: Color.accent
              horizontalAlignment: Text.AlignRight
              Layout.preferredWidth: Style.space(48)
            }
          }

          // Opacity Slider
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            Text {
              text: "Opacity:"
              font.pixelSize: 11
              color: Color.foreground
              Layout.preferredWidth: Style.space(55)
            }

            PanelSlider {
              Layout.fillWidth: true
              minimum: 1
              maximum: 100
              step: 1
              integer: true
              value: root.stampOpacity
              onMoved: function(val) {
                root.stampOpacity = Math.round(val)
              }
              onReleased: function(val) {
                root.stampOpacity = Math.round(val)
                root.saveConfig()
              }
            }

            Text {
              text: root.stampOpacity + "%"
              font.pixelSize: 11
              font.bold: true
              color: Color.accent
              horizontalAlignment: Text.AlignRight
              Layout.preferredWidth: Style.space(48)
            }
          }

          // Rotation Slider
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            Text {
              text: "Rotation:"
              font.pixelSize: 11
              color: Color.foreground
              Layout.preferredWidth: Style.space(55)
            }

            PanelSlider {
              Layout.fillWidth: true
              minimum: -180
              maximum: 180
              step: 5
              integer: true
              value: root.rotationAngle
              onMoved: function(val) {
                root.rotationAngle = Math.round(val)
              }
              onReleased: function(val) {
                root.rotationAngle = Math.round(val)
                root.saveConfig()
              }
            }

            Text {
              text: root.rotationAngle + "°"
              font.pixelSize: 11
              font.bold: true
              color: Color.accent
              horizontalAlignment: Text.AlignRight
              Layout.preferredWidth: Style.space(48)
            }
          }

          // Edge Margin Slider
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            Text {
              text: "Margin:"
              font.pixelSize: 11
              color: Color.foreground
              Layout.preferredWidth: Style.space(55)
            }

            PanelSlider {
              Layout.fillWidth: true
              minimum: 0
              maximum: 200
              step: 4
              integer: true
              value: root.margin
              onMoved: function(val) {
                root.margin = Math.round(val)
              }
              onReleased: function(val) {
                root.margin = Math.round(val)
                root.saveConfig()
              }
            }

            Text {
              text: root.margin + "px"
              font.pixelSize: 11
              font.bold: true
              color: Color.accent
              horizontalAlignment: Text.AlignRight
              Layout.preferredWidth: Style.space(48)
            }
          }
        }

        // -------------------------------------------------------------
        // Additional Options (Drop Shadow & Primary Screen Only)
        // -------------------------------------------------------------
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(12)

          RowLayout {
            spacing: Style.space(6)
            ToggleSwitch {
              checked: root.showShadow
              onToggled: {
                root.showShadow = !root.showShadow
                root.saveConfig()
              }
            }
            Text {
              text: "Drop Shadow"
              font.pixelSize: 11
              color: Color.foreground
            }
          }

          Item { Layout.fillWidth: true }

          RowLayout {
            spacing: Style.space(6)
            ToggleSwitch {
              checked: root.primaryScreenOnly
              onToggled: {
                root.primaryScreenOnly = !root.primaryScreenOnly
                root.saveConfig()
              }
            }
            Text {
              text: "Primary Display Only"
              font.pixelSize: 11
              color: Color.foreground
            }
          }
        }

        PanelSeparator {
          Layout.fillWidth: true
        }

        // -------------------------------------------------------------
        // Footer Actions
        // -------------------------------------------------------------
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)

          Button {
            text: "↺ Reset Defaults"
            bordered: true
            onClicked: root.resetDefaults()
          }

          Item { Layout.fillWidth: true }

          Button {
            text: "Done"
            selected: true
            onClicked: root.close()
          }
        }
      }
    }
  }
}

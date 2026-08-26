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
  property string textFont: "modern-sans"
  property string renderedAscii: ""
  property bool primaryScreenOnly: false

  readonly property bool isAsciiFont: textFont !== "modern-sans" && textFont !== "mono" && textFont !== "serif" && textFont !== "display" && textFont !== "condensed"

  function fontFamilyFor(fontId) {
    if (fontId === "mono") return (Style.fontMonospace ? Style.fontMonospace.family : "monospace")
    if (fontId === "serif") return "serif"
    if (fontId === "display") return (Style.fontDisplay ? Style.fontDisplay.family : "sans-serif")
    if (fontId === "condensed") return "sans-serif"
    return (Style.fontBold ? Style.fontBold.family : "sans-serif")
  }

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

  readonly property var fontOptions: [
    { value: "modern-sans", label: "Modern Sans (Typography)" },
    { value: "mono", label: "Monospace (Typography)" },
    { value: "serif", label: "Classic Serif (Typography)" },
    { value: "display", label: "Display Impact (Typography)" },
    { value: "condensed", label: "Tall Condensed (Typography)" },
    { value: "slant", label: "Slant (ASCII Art)" },
    { value: "standard", label: "Standard (ASCII Art)" },
    { value: "block", label: "Block (ASCII Art)" },
    { value: "banner", label: "Banner (ASCII Art)" },
    { value: "doom", label: "Doom (ASCII Art)" },
    { value: "epic", label: "Epic (ASCII Art)" },
    { value: "starwars", label: "Star Wars (ASCII Art)" },
    { value: "isometric1", label: "Isometric (ASCII Art)" },
    { value: "graffiti", label: "Graffiti (ASCII Art)" },
    { value: "speed", label: "Speed (ASCII Art)" },
    { value: "sub-zero", label: "Sub-Zero (ASCII Art)" },
    { value: "cyberlarge", label: "Cyber (ASCII Art)" },
    { value: "shadow", label: "Shadow (ASCII Art)" },
    { value: "alligator", label: "Alligator (ASCII Art)" },
    { value: "delta_corps_priest_1", label: "Delta Corps (ASCII Art)" }
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
    { id: "theme-accent", label: "Accent", color: Color.accent },
    { id: "theme-fg", label: "Text", color: Color.foreground },
    { id: "white", label: "White", color: "#ffffff" },
    { id: "black", label: "Black", color: "#000000" },
    { id: "original", label: "Original", color: "transparent" },
    { id: "custom", label: "Custom", color: (root.customColor || "#ffffff") }
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
            if (cfg.textFont !== undefined) root.textFont = String(cfg.textFont)
            if (cfg.renderedAscii !== undefined) root.renderedAscii = String(cfg.renderedAscii)
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
      "textFont": root.textFont,
      "renderedAscii": root.renderedAscii,
      "primaryScreenOnly": root.primaryScreenOnly
    }
    configFile.setText(JSON.stringify(payload, null, 2) + "\n")
  }

  function updateTextSettings() {
    root.saveConfig()
    Util.execDetached("omastamp set-text " + Util.shellQuote(root.customText) + " --font " + Util.shellQuote(root.textFont))
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
    root.textFont = "modern-sans"
    root.renderedAscii = ""
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
    Util.execDetached("omastamp browse")
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
            Item {
              width: Style.space(26)
              height: Style.space(26)

              Image {
                anchors.fill: parent
                source: Qt.resolvedUrl("assets/icon.svg")
                sourceSize: Qt.size(52, 52)
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true

                layer.enabled: true
                layer.effect: MultiEffect {
                  colorization: 1.0
                  colorizationColor: root.stampEnabled ? Color.accent : Qt.darker(Color.foreground, 1.4)
                }
              }
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
              root.updateTextSettings()
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
                height: Style.space(64)
                radius: Style.cornerRadius
                clip: true
                color: (root.presetId === modelData.id)
                  ? Util.alpha(Color.accent, 0.22)
                  : (presetMouse.containsMouse ? Util.alpha(Color.foreground, 0.08) : Util.alpha(Color.popups.background, 0.6))
                border.color: (root.presetId === modelData.id) ? Color.accent : Util.alpha(Color.popups.border, 0.45)
                border.width: (root.presetId === modelData.id) ? 2 : 1

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: Style.space(4)
                  spacing: Style.space(2)

                  Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Image {
                      anchors.centerIn: parent
                      width: Math.min(parent.width, Style.space(38))
                      height: Math.min(parent.height, Style.space(26))
                      source: Qt.resolvedUrl(modelData.icon)
                      sourceSize: Qt.size(80, 80)
                      fillMode: Image.PreserveAspectFit
                      smooth: true
                      mipmap: true
                      opacity: (root.presetId === modelData.id) ? 1.0 : 0.85
                      layer.enabled: true
                      layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: Color.accent
                      }
                    }
                  }

                  Text {
                    Layout.fillWidth: true
                    text: modelData.name
                    font.family: Style.fontRegular ? Style.fontRegular.family : "sans-serif"
                    font.pixelSize: 9
                    font.bold: root.presetId === modelData.id
                    color: (root.presetId === modelData.id) ? Color.accent : Color.foreground
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
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
              source: (root.customImagePath && (root.customImagePath.indexOf("/") === 0 || root.customImagePath.indexOf("file://") === 0)) ? Util.fileUrl(root.customImagePath) : ""
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
        // Content 3: Watermark Text Input & Font Dropdown
        // -------------------------------------------------------------
        ColumnLayout {
          Layout.fillWidth: true
          visible: root.mode === "text"
          spacing: Style.space(8)

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(2)

            Text {
              text: "Watermark Text / Wordmark:"
              font.pixelSize: 10
              color: Color.foreground
            }

            TextField {
              Layout.fillWidth: true
              text: root.customText
              placeholderText: "e.g. OMARCHY"
              onEditingFinished: {
                root.customText = text.trim()
                root.updateTextSettings()
              }
            }
          }

          // Font Selector Dropdown
          Dropdown {
            Layout.fillWidth: true
            label: "Typography & ASCII Style:"
            options: root.fontOptions
            value: root.textFont
            fontFamily: root.fontFamily
            onChanged: function(v) {
              root.textFont = v
              root.mode = "text"
              root.updateTextSettings()
            }
          }

          // Live Text Watermark Preview Box (with Auto-Scaling to fit all text!)
          Rectangle {
            Layout.fillWidth: true
            height: Style.space(96)
            radius: Style.cornerRadius
            clip: true
            color: Util.alpha(Color.popups.background, 0.5)
            border.color: Util.alpha(Color.popups.border, 0.4)
            border.width: 1

            Item {
              anchors.fill: parent
              anchors.margins: Style.space(8)
              clip: true

              // ASCII Art Preview (strictly monospace, left-aligned characters inside centered box)
              Item {
                anchors.centerIn: parent
                visible: root.isAsciiFont
                width: previewAsciiText.implicitWidth
                height: previewAsciiText.implicitHeight
                scale: Math.min(1.0, Math.min((parent.width - Style.space(8)) / Math.max(1, previewAsciiText.implicitWidth), (parent.height - Style.space(8)) / Math.max(1, previewAsciiText.implicitHeight)))
                transformOrigin: Item.Center

                Text {
                  id: previewAsciiText
                  anchors.centerIn: parent
                  text: root.renderedAscii || root.customText
                  color: (root.tintMode === "theme-accent") ? Color.accent : ((root.tintMode === "theme-fg") ? Color.foreground : (root.customColor || "#ffffff"))
                  textFormat: Text.PlainText
                  font.family: "monospace"
                  font.kerning: false
                  font.hintingPreference: Font.PreferFullHinting
                  font.pixelSize: 10
                  lineHeight: 1.0
                  lineHeightMode: Text.ProportionalHeight
                  horizontalAlignment: Text.AlignLeft
                }
              }

              // Pro Typography Preview
              Item {
                anchors.centerIn: parent
                visible: !root.isAsciiFont
                width: previewProText.implicitWidth
                height: previewProText.implicitHeight
                scale: Math.min(1.0, Math.min((parent.width - Style.space(8)) / Math.max(1, previewProText.implicitWidth), (parent.height - Style.space(8)) / Math.max(1, previewProText.implicitHeight)))
                transformOrigin: Item.Center

                Text {
                  id: previewProText
                  anchors.centerIn: parent
                  text: root.customText
                  color: (root.tintMode === "theme-accent") ? Color.accent : ((root.tintMode === "theme-fg") ? Color.foreground : (root.customColor || "#ffffff"))
                  font.family: root.fontFamilyFor(root.textFont)
                  font.pixelSize: 22
                  font.bold: true
                  font.letterSpacing: (root.textFont === "mono" || root.textFont === "condensed") ? 4 : 2
                  font.capitalization: (root.textFont === "condensed" || root.textFont === "display") ? Font.AllUppercase : Font.MixedCase
                  horizontalAlignment: Text.AlignHCenter
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
                delegate: Rectangle {
                  id: tintBtn
                  required property var modelData
                  Layout.fillWidth: true
                  height: Style.space(28)
                  radius: Style.cornerRadius
                  color: (root.tintMode === modelData.id)
                    ? Util.alpha(Color.accent, 0.22)
                    : (tintMouse.containsMouse ? Util.alpha(Color.foreground, 0.1) : Util.alpha(Color.popups.background, 0.6))
                  border.color: (root.tintMode === modelData.id) ? Color.accent : Util.alpha(Color.popups.border, 0.45)
                  border.width: (root.tintMode === modelData.id) ? 2 : 1

                  RowLayout {
                    anchors.centerIn: parent
                    spacing: Style.space(5)

                    Rectangle {
                      visible: modelData.id !== "original"
                      width: Style.space(8)
                      height: Style.space(8)
                      radius: width / 2
                      color: (modelData.id === "custom") ? (root.customColor || "#ffffff") : modelData.color
                      border.color: Util.alpha(Color.foreground, 0.3)
                      border.width: 1
                    }

                    Text {
                      text: modelData.label
                      font.family: Style.fontRegular ? Style.fontRegular.family : "sans-serif"
                      font.pixelSize: 11
                      font.bold: root.tintMode === modelData.id
                      color: (root.tintMode === modelData.id) ? Color.accent : Color.foreground
                    }
                  }

                  MouseArea {
                    id: tintMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      root.tintMode = modelData.id
                      root.saveConfig()
                    }
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

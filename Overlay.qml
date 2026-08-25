import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons

Item {
  id: root

  // -------------------------------------------------------------
  // Configuration State
  // -------------------------------------------------------------
  property bool stampEnabled: true
  property string mode: "preset" // "preset" | "image" | "text"
  property string presetId: "omarchy"
  property string position: "center"
  property int stampSize: 280
  property int stampOpacity: 30
  property string tintMode: "theme-accent" // "theme-accent" | "theme-fg" | "original" | "white" | "black" | "custom"
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

  // Injected properties from shell if available
  property var shell: null
  property var manifest: null

  readonly property string stateFilePath: Quickshell.env("HOME") + "/.local/state/omarchy/omastamp/config.json"

  // Resolved color for tinting
  readonly property color resolvedTintColor: {
    if (tintMode === "theme-accent") return Color.accent
    if (tintMode === "theme-fg") return Color.foreground
    if (tintMode === "white") return "#ffffff"
    if (tintMode === "black") return "#000000"
    if (tintMode === "custom") return (customColor && customColor.length > 0) ? customColor : "#ffffff"
    return "#ffffff"
  }

  readonly property bool applyColorization: tintMode !== "original" && mode !== "text"

  // Watch state.json for reactive updates across processes & CLI
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
        console.warn("OmaStamp: error parsing config.json:", e)
      }
    }
  }

  // -------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------
  function saveState() {
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

  function toggle() {
    root.stampEnabled = !root.stampEnabled
    saveState()
  }

  function setEnabled(val) {
    root.stampEnabled = Boolean(val)
    saveState()
  }

  function setPreset(name) {
    root.mode = "preset"
    root.presetId = String(name)
    saveState()
  }

  function setPosition(pos) {
    root.position = String(pos)
    saveState()
  }

  function setOpacity(val) {
    root.stampOpacity = Math.max(0, Math.min(100, Number(val)))
    saveState()
  }

  function setSize(val) {
    root.stampSize = Math.max(32, Math.min(1000, Number(val)))
    saveState()
  }

  // -------------------------------------------------------------
  // IPC Handler
  // -------------------------------------------------------------
  IpcHandler {
    target: "omastamp"

    function toggle(): void {
      root.toggle()
    }

    function on(): void {
      root.setEnabled(true)
    }

    function off(): void {
      root.setEnabled(false)
    }

    function setPreset(name: string): void {
      root.setPreset(name)
    }

    function setPosition(pos: string): void {
      root.setPosition(pos)
    }

    function setOpacity(val: string): void {
      root.setOpacity(parseInt(val, 10))
    }

    function setSize(val: string): void {
      root.setSize(parseInt(val, 10))
    }

    function setTint(mode: string): void {
      root.tintMode = mode
      root.saveState()
    }

    function refresh(): void {
      configFile.reload()
    }
  }

  // -------------------------------------------------------------
  // Fullscreen Desktop Overlay Variants (Per Screen)
  // -------------------------------------------------------------
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: win
      required property var modelData

      screen: modelData
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      anchors { top: true; bottom: true; left: true; right: true }

      WlrLayershell.namespace: "omastamp-overlay"
      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      // Empty input mask makes the overlay 100% click-through!
      // Mouse clicks pass directly through to desktop wallpaper & windows.
      mask: Region {}

      visible: root.stampEnabled && (!root.primaryScreenOnly || (Quickshell.screens.length > 0 && modelData === Quickshell.screens[0]))

      Item {
        id: stampContainer
        anchors.fill: parent

        // ---------------------------------------------------------
        // Stamp Element Box
        // ---------------------------------------------------------
        Item {
          id: stampItem

          readonly property real baseWidth: root.stampSize
          readonly property real baseHeight: (root.mode === "text" && root.customSubtext.length > 0)
            ? Math.round(root.stampSize * 0.75)
            : ((root.mode === "preset" && root.presetId === "omarchy-text")
                ? Math.round(root.stampSize * 0.28)
                : root.stampSize)

          width: baseWidth
          height: baseHeight

          // Calculate X coordinate based on alignment
          readonly property real targetX: {
            var m = root.margin
            var sw = stampItem.width
            var pw = win.width
            if (root.position === "top-left" || root.position === "center-left" || root.position === "bottom-left") {
              return m + root.offsetX
            }
            if (root.position === "top-right" || root.position === "center-right" || root.position === "bottom-right") {
              return pw - sw - m + root.offsetX
            }
            // center / top-center / bottom-center
            return (pw - sw) / 2 + root.offsetX
          }

          // Calculate Y coordinate based on alignment
          readonly property real targetY: {
            var m = root.margin
            var sh = stampItem.height
            var ph = win.height
            if (root.position === "top-left" || root.position === "top-center" || root.position === "top-right") {
              return m + root.offsetY
            }
            if (root.position === "bottom-left" || root.position === "bottom-center" || root.position === "bottom-right") {
              return ph - sh - m + root.offsetY
            }
            // center / center-left / center-right
            return (ph - sh) / 2 + root.offsetY
          }

          x: targetX
          y: targetY

          // Smooth animation on transitions
          Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
          Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
          Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
          Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
          Behavior on rotation { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

          opacity: root.stampEnabled ? (root.stampOpacity / 100.0) : 0
          rotation: root.rotationAngle
          transformOrigin: Item.Center

          // Visual effect layer for colorization & drop shadow
          layer.enabled: root.applyColorization || root.showShadow
          layer.smooth: true
          layer.effect: MultiEffect {
            colorization: root.applyColorization ? 1.0 : 0.0
            colorizationColor: root.resolvedTintColor
            shadowEnabled: root.showShadow
            shadowColor: "#80000000"
            shadowBlur: 0.6
            shadowHorizontalOffset: 2
            shadowVerticalOffset: 4
          }

          // -------------------------------------------------------
          // Content 1: Preset Vector SVG
          // -------------------------------------------------------
          Image {
            id: presetImage
            anchors.fill: parent
            visible: root.mode === "preset"
            source: root.mode === "preset" ? Qt.resolvedUrl("assets/logos/" + root.presetId + ".svg") : ""
            sourceSize.width: root.stampSize
            sourceSize.height: root.stampSize
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            mipmap: true
          }

          // -------------------------------------------------------
          // Content 2: Custom Image File
          // -------------------------------------------------------
          Image {
            id: customImage
            anchors.fill: parent
            visible: root.mode === "image" && root.customImagePath !== ""
            source: (root.mode === "image" && root.customImagePath && (root.customImagePath.indexOf("/") === 0 || root.customImagePath.indexOf("file://") === 0)) ? Util.fileUrl(root.customImagePath) : ""
            sourceSize.width: root.stampSize
            sourceSize.height: root.stampSize
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            mipmap: true
          }

          // -------------------------------------------------------
          // Content 3: Typographic Text Watermark
          // -------------------------------------------------------
          ColumnLayout {
            id: textLayout
            anchors.centerIn: parent
            visible: root.mode === "text"
            spacing: Style.space(6)

            Text {
              id: mainText
              Layout.alignment: Qt.AlignHCenter
              text: root.customText
              color: root.resolvedTintColor
              font.family: Style.fontBold ? Style.fontBold.family : "sans-serif"
              font.pixelSize: Math.max(16, Math.round(root.stampSize * 0.22))
              font.bold: true
              font.letterSpacing: 4
              font.capitalization: Font.AllUppercase
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              id: subText
              Layout.alignment: Qt.AlignHCenter
              visible: root.customSubtext.length > 0
              text: root.customSubtext
              color: root.resolvedTintColor
              opacity: 0.75
              font.family: Style.fontRegular ? Style.fontRegular.family : "sans-serif"
              font.pixelSize: Math.max(10, Math.round(root.stampSize * 0.08))
              font.letterSpacing: 3
              font.capitalization: Font.AllUppercase
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }
      }
    }
  }
}

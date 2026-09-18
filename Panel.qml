import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "harshith.autoheal"
  ipcTarget: "harshith.autoheal.panel"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property string scriptPath:
    Qt.resolvedUrl("autoheal-plugin-engine.sh").toString().replace(/^file:\/\//, "")

  property string status: "UNAVAILABLE"
  property int latencyMs: -1
  property int memoryRules: 0
  property var toolchains: { "python": "Not Found", "uv": "Not Found", "node": "Not Found", "docker": "Offline", "git": "Not Found" }
  property var recentHeals: []

  readonly property color fg: bar ? bar.foreground : Color.popups.text
  readonly property color bg: Color.popups.background
  readonly property color accent: Color.accent
  readonly property string fontFam: bar ? bar.fontFamily : Style.font.family

  function open() {
    root.controller.show()
    root.refresh()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function refresh() {
    stateProc.command = ["bash", scriptPath, "get"]
    stateProc.running = true
  }

  function runTest() {
    actionProc.command = ["bash", scriptPath, "test"]
    actionProc.running = true
  }

  Process {
    id: stateProc
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          if (data.status) root.status = data.status
          root.latencyMs = data.reflex_latency_ms !== null && data.reflex_latency_ms !== undefined ? data.reflex_latency_ms : -1
          if (data.memory_rules !== undefined) root.memoryRules = data.memory_rules
          if (data.toolchains) root.toolchains = data.toolchains
          if (data.recent_heals) root.recentHeals = data.recent_heals
        } catch(e) {}
      }
    }
  }

  Process {
    id: actionProc
    running: false
    onExited: root.refresh()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight, Style.space(520))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
    }

    ScrollView {
      id: scrollArea
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.bottomMargin: -panel.padding
      clip: true
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical.policy: panelColumn.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

      Column {
        id: panelColumn
        width: scrollArea.availableWidth
        spacing: Style.space(12)

        // Hero Header
        Item {
          width: parent.width
          implicitHeight: boltIcon.implicitHeight

          Text {
            id: boltIcon
            textFormat: Text.PlainText
            text: "󱐌"
            color: root.accent
            font.family: root.fontFam
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            anchors.left: boltIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Row {
              spacing: Style.space(6)
              Text {
                textFormat: Text.PlainText
                text: "AutoHeal Cockpit"
                color: root.accent
                font.family: root.fontFam
                font.pixelSize: Style.font.title
                font.bold: true
              }
              Text {
                textFormat: Text.PlainText
                text: "[" + root.status + "]"
                color: "#38ef7d"
                font.family: root.fontFam
                font.pixelSize: Style.font.caption
                font.bold: true
              }
            }

            Text {
              textFormat: Text.PlainText
              text: (root.latencyMs >= 0 ? "⚡ Reflex Latency: " + root.latencyMs + "ms" : "⚡ Reflex latency: not measured") + "  •  🧠 " + root.memoryRules + " Learned Rules"
              color: Qt.darker(root.fg, 1.4)
              font.family: root.fontFam
              font.pixelSize: Style.font.caption
            }
          }
        }

        PanelSeparator { width: parent.width }

        PanelSectionHeader { text: "Toolchain Doctor" }

        // Toolchains Grid
        Row {
          width: parent.width
          spacing: Style.space(6)

          Rectangle {
            width: (parent.width - Style.space(12)) / 3
            height: Style.space(42)
            radius: Style.space(6)
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)

            Column {
              anchors.centerIn: parent
              spacing: 2
              Text { textFormat: Text.PlainText; text: "Python / UV"; font.pixelSize: Style.font.caption; color: Qt.darker(root.fg, 1.4) }
              Text { textFormat: Text.PlainText; text: root.toolchains.python; font.pixelSize: Style.font.caption; font.bold: true; color: root.toolchains.python === "Not Found" ? "#ffb86c" : "#38ef7d" }
            }
          }

          Rectangle {
            width: (parent.width - Style.space(12)) / 3
            height: Style.space(42)
            radius: Style.space(6)
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)

            Column {
              anchors.centerIn: parent
              spacing: 2
              Text { textFormat: Text.PlainText; text: "Node / Pnpm"; font.pixelSize: Style.font.caption; color: Qt.darker(root.fg, 1.4) }
              Text { textFormat: Text.PlainText; text: root.toolchains.node; font.pixelSize: Style.font.caption; font.bold: true; color: root.toolchains.node === "Not Found" ? "#ffb86c" : "#38ef7d" }
            }
          }

          Rectangle {
            width: (parent.width - Style.space(12)) / 3
            height: Style.space(42)
            radius: Style.space(6)
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)

            Column {
              anchors.centerIn: parent
              spacing: 2
              Text { textFormat: Text.PlainText; text: "Docker / Git"; font.pixelSize: Style.font.caption; color: Qt.darker(root.fg, 1.4) }
              Text { textFormat: Text.PlainText; text: root.toolchains.docker + " / " + root.toolchains.git; font.pixelSize: Style.font.caption; font.bold: true; color: "#38ef7d" }
            }
          }
        }

        PanelSeparator { width: parent.width }

        PanelSectionHeader { text: "Recent Reflex Heals" }

        // Recent Heals List
        Column {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.recentHeals
            delegate: Rectangle {
              required property var modelData
              width: panelColumn.width
              height: Style.space(44)
              radius: Style.space(6)
              color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)

              Item {
                anchors.fill: parent
                anchors.leftMargin: Style.space(8)
                anchors.rightMargin: Style.space(8)

                Column {
                  anchors.left: parent.left
                  anchors.right: timeTxt.left
                  anchors.rightMargin: Style.space(6)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(2)

                  Text {
                    textFormat: Text.PlainText
                    text: modelData.error
                    font.family: root.fontFam
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    color: root.fg
                  }

                  Text {
                    textFormat: Text.PlainText
                    text: "⚡ " + modelData.fix
                    font.family: root.fontFam
                    font.pixelSize: Style.font.caption
                    color: "#38ef7d"
                  }
                }

                Text {
                  id: timeTxt
                  textFormat: Text.PlainText
                  text: modelData.time
                  font.family: root.fontFam
                  font.pixelSize: Style.font.caption
                  color: Qt.darker(root.fg, 1.5)
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }
          }
        }

        PanelSeparator { width: parent.width }

        // Actions
        Row {
          width: parent.width
          spacing: Style.space(8)

          Rectangle {
            width: parent.width - Style.space(44)
            height: Style.space(34)
            radius: Style.space(6)
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
            border.color: root.accent
            border.width: 1

            Row {
              anchors.centerIn: parent
              spacing: Style.space(6)
              Text { textFormat: Text.PlainText; text: "🧪"; font.pixelSize: Style.font.body }
              Text {
                textFormat: Text.PlainText
                text: "Test Reflex Engines"
                font.family: root.fontFam
                font.pixelSize: Style.font.body
                font.bold: true
                color: root.accent
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.runTest()
            }
          }

          Rectangle {
            width: Style.space(36)
            height: Style.space(34)
            radius: Style.space(6)
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)

            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: "🔄"
              font.pixelSize: Style.font.body
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.refresh()
            }
          }
        }
      }
    }
  }
}

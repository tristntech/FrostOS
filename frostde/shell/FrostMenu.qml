// A drop-down menu, like the menus in a Mac menu bar.
//
// items: a list of { text, action, hint?, enabled?, checked? } or { separator: true }
// Clicking outside the menu closes it.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: menu

    property var items: []
    property Item anchorItem: null
    property var ownerWindow: null        // clicks here don't close the menu
    property bool opensUp: false          // true for menus that open above (the dock)

    function open() { visible = true; }
    function close() { visible = false; }
    function toggle() { visible = !visible; }

    anchor.item: anchorItem
    anchor.edges: opensUp ? Edges.Top : (Edges.Bottom | Edges.Left)
    anchor.gravity: opensUp ? Edges.Top : (Edges.Bottom | Edges.Right)
    anchor.margins.top: opensUp ? -6 : 4

    visible: false
    color: "transparent"
    implicitWidth: Math.max(230, list.implicitWidth + 12)
    implicitHeight: list.implicitHeight + 12

    HyprlandFocusGrab {
        windows: menu.ownerWindow ? [menu, menu.ownerWindow] : [menu]
        active: menu.visible
        onCleared: menu.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.panel
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            id: list
            anchors.fill: parent
            anchors.margins: 6
            spacing: 0

            Repeater {
                model: menu.items

                delegate: Item {
                    id: row
                    required property var modelData
                    readonly property bool isSeparator: modelData.separator === true
                    readonly property bool isEnabled: !isSeparator && modelData.enabled !== false

                    Layout.fillWidth: true
                    implicitHeight: isSeparator ? 11 : 26
                    implicitWidth: isSeparator ? 0 : label.implicitWidth + hint.implicitWidth + 48

                    Rectangle {
                        visible: row.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        height: 1
                        color: Theme.separator
                    }

                    Rectangle {
                        visible: !row.isSeparator
                        anchors.fill: parent
                        radius: 6
                        color: mouse.containsMouse && row.isEnabled ? Theme.accent : "transparent"
                    }

                    Label {
                        id: check
                        visible: !row.isSeparator && row.modelData.checked === true
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✓"
                        color: mouse.containsMouse ? Theme.textOnAccent : Theme.text
                    }

                    Label {
                        id: label
                        visible: !row.isSeparator
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.text || ""
                        color: !row.isEnabled ? Theme.textSecondary
                             : mouse.containsMouse ? Theme.textOnAccent : Theme.text
                    }

                    Label {
                        id: hint
                        visible: !row.isSeparator
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.hint || ""
                        secondary: true
                        color: mouse.containsMouse && row.isEnabled ? Theme.textOnAccent : Theme.textSecondary
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: row.isEnabled
                        onClicked: {
                            menu.visible = false;
                            if (row.modelData.action)
                                row.modelData.action();
                        }
                    }
                }
            }
        }
    }
}

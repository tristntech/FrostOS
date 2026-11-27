// Launchpad: every app in a full-screen grid, with a search field.
// Open it from the dock or with Super+A. Esc or a click on empty space closes it.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: pad
    screen: Overlays.activeScreen
    visible: Overlays.launchpadOpen

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "frostde-launchpad"
    WlrLayershell.keyboardFocus: Overlays.launchpadOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string query: ""

    readonly property var apps: {
        const q = query.trim().toLowerCase();
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .filter(e => q === "" || e.name.toLowerCase().includes(q)
                         || (e.genericName || "").toLowerCase().includes(q)
                         || e.keywords.some(k => k.toLowerCase().includes(q)))
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    function launch(entry) {
        entry.execute();
        Overlays.closeAll();
    }

    onVisibleChanged: {
        if (visible) {
            query = "";
            search.text = "";
            search.forceActiveFocus();
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: Overlays.launchpadOpen ? 1 : 0
        scale: Overlays.launchpadOpen ? 1 : 1.06
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: Theme.shade
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Overlays.closeAll()
        }

        // Search field
        Rectangle {
            id: searchBox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 56
            width: 280
            height: 34
            radius: 10
            color: Theme.tile
            border.color: Theme.border
            border.width: 1

            Icon {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: 11
                anchors.verticalCenter: parent.verticalCenter
                text: Glyphs.search
                size: 13
                color: Theme.textSecondary
            }

            TextInput {
                id: search
                anchors.left: searchIcon.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 15
                clip: true
                onTextChanged: pad.query = text
                Keys.onEscapePressed: Overlays.closeAll()
                Keys.onReturnPressed: {
                    if (pad.apps.length > 0)
                        pad.launch(pad.apps[0]);
                }

                Label {
                    visible: search.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search"
                    secondary: true
                    font.pixelSize: 15
                }
            }
        }

        GridView {
            id: grid
            anchors.top: searchBox.bottom
            anchors.topMargin: 40
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 120
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property int columns: Math.max(3, Math.min(7, Math.floor((pad.width - 160) / cellWidth)))
            width: columns * cellWidth
            cellWidth: 150
            cellHeight: 140
            clip: true
            model: pad.apps
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: app
                required property var modelData
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 8
                    radius: Theme.radius
                    color: appMouse.containsMouse ? Theme.hover : "transparent"
                }

                IconImage {
                    id: appIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    implicitSize: 76
                    mipmap: true
                    source: Quickshell.iconPath(app.modelData.icon, "application-x-executable")
                    scale: appMouse.pressed ? 0.92 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                }

                Label {
                    anchors.top: appIcon.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 16
                    horizontalAlignment: Text.AlignHCenter
                    text: app.modelData.name
                    color: "#FFFFFF"
                    style: Text.Raised
                    styleColor: Qt.rgba(0, 0, 0, 0.35)
                }

                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: pad.launch(app.modelData)
                }
            }
        }
    }
}

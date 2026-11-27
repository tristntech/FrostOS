// Notification Center: click the date and time in the menu bar.
// Shows today's date and every notification you haven't cleared.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: center
    screen: Overlays.activeScreen
    visible: Overlays.notificationCenterOpen

    anchors { top: true; right: true; bottom: true }
    margins { top: 6; right: 8; bottom: 90 }
    implicitWidth: 370
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "frostde-notificationcenter"

    HyprlandFocusGrab {
        windows: [center]
        active: center.visible
        onCleared: Overlays.closeAll()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: header
        x: 8
        width: parent.width - 16
        spacing: 2

        Label {
            text: Qt.formatDate(clock.date, "dddd")
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: "#FFFFFF"
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.3)
        }
        Label {
            text: Qt.formatDate(clock.date, "d MMMM")
            font.pixelSize: 30
            font.weight: Font.Light
            color: "#FFFFFF"
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.3)
        }
    }

    Rectangle {
        id: clearButton
        visible: Notifs.all.length > 0
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.bottom: header.bottom
        width: clearLabel.implicitWidth + 22
        height: 26
        radius: 13
        color: clearMouse.containsMouse ? Theme.hover : Theme.panel
        border.color: Theme.border
        border.width: 1
        Label {
            id: clearLabel
            anchors.centerIn: parent
            text: "Clear All"
            font.pixelSize: 12
        }
        MouseArea {
            id: clearMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Notifs.clearAll()
        }
    }

    Rectangle {
        visible: Notifs.all.length === 0
        anchors.top: header.bottom
        anchors.topMargin: 14
        x: 8
        width: parent.width - 16
        height: 64
        radius: Theme.radiusLarge
        color: Theme.panel
        border.color: Theme.border
        border.width: 1
        Label {
            anchors.centerIn: parent
            text: "No Notifications"
            secondary: true
        }
    }

    ListView {
        anchors.top: header.bottom
        anchors.topMargin: 14
        anchors.bottom: parent.bottom
        x: 8
        width: parent.width - 16
        spacing: 8
        clip: true
        model: Notifs.all.slice().reverse()

        delegate: NotificationCard {
            required property var modelData
            notification: modelData
            width: ListView.view.width
            onCloseRequested: modelData.dismiss()
        }
    }
}

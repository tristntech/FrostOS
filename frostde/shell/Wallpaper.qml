// The desktop background. Switches between the light and dark wallpaper.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "frostde-wallpaper"
    color: Theme.dark ? "#0B1828" : "#C5E8FF"

    Image {
        id: light
        anchors.fill: parent
        source: "file://" + Config.wallpaperLight
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: win.width
        sourceSize.height: win.height
    }

    Image {
        anchors.fill: parent
        source: "file://" + Config.wallpaperDark
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: win.width
        sourceSize.height: win.height
        opacity: Theme.dark ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.InOutQuad } }
    }

    // Clicking the desktop closes any open FrostDE overlay.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: Overlays.closeAll()
    }
}

// One notification, as a frosted card (used for banners and the Notification Center).
import QtQuick
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: card
    required property var notification
    signal closeRequested()

    implicitHeight: Math.max(68, text.implicitHeight + 24)
    radius: Theme.radiusLarge
    color: Theme.panel
    border.color: Theme.border
    border.width: 1

    readonly property string iconSource: {
        const n = notification;
        if (!n)
            return "";
        if (n.image)
            return n.image;
        if (n.appIcon)
            return n.appIcon.startsWith("/") || n.appIcon.includes("://")
                   ? n.appIcon : Quickshell.iconPath(n.appIcon, "dialog-information");
        return Quickshell.iconPath(n.desktopEntry || "dialog-information", "dialog-information");
    }

    IconImage {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 14
        implicitSize: 36
        source: card.iconSource
    }

    Column {
        id: text
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: parent.top
        anchors.topMargin: 12
        spacing: 2

        Label {
            width: parent.width
            text: card.notification ? card.notification.appName : ""
            secondary: true
            font.pixelSize: 11
            visible: text !== ""
        }
        Label {
            width: parent.width
            text: card.notification ? card.notification.summary : ""
            font.weight: Font.DemiBold
        }
        Label {
            width: parent.width
            text: card.notification ? card.notification.body : ""
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 4
            visible: text !== ""
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Notifs.activate(card.notification)
    }

    // Close button, shown on hover (top left, like on a Mac)
    Rectangle {
        visible: mouse.containsMouse || closeMouse.containsMouse
        x: -6
        y: -6
        width: 20
        height: 20
        radius: 10
        color: Theme.panel
        border.color: Theme.border
        border.width: 1
        Icon {
            anchors.centerIn: parent
            text: Glyphs.close
            size: 9
        }
        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: card.closeRequested()
        }
    }
}

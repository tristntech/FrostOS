// A clickable item in the menu bar: text, an icon glyph, or anything inside.
import QtQuick

Item {
    id: button
    property string text: ""
    property string glyph: ""
    property bool bold: false
    property bool active: false            // e.g. its menu is open
    property real glyphSize: 14
    default property alias content: extra.data
    signal clicked(var mouse)

    implicitHeight: Theme.menuBarHeight - 6
    implicitWidth: Math.max(implicitHeight, (glyph ? icon.implicitWidth : 0) + (text ? label.implicitWidth : 0) + extra.childrenRect.width + 16)

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: button.active ? Theme.hover : (mouse.containsMouse ? Theme.hover : "transparent")
    }

    Row {
        anchors.centerIn: parent
        spacing: 5

        Icon {
            id: icon
            visible: button.glyph !== ""
            text: button.glyph
            size: button.glyphSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Label {
            id: label
            visible: button.text !== ""
            text: button.text
            font.weight: button.bold ? Font.Bold : Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            id: extra
            width: childrenRect.width
            height: childrenRect.height
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => button.clicked(m)
    }
}

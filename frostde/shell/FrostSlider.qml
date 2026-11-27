// A wide rounded slider like the ones in the Mac Control Center.
import QtQuick

Item {
    id: slider
    property real value: 0                 // 0..1
    property string glyph: ""
    signal moved(real value)

    implicitHeight: 28

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.tile
        border.color: Theme.border
        border.width: 1
        clip: true

        Rectangle {
            height: parent.height
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, slider.value)))
            radius: height / 2
            color: "#FFFFFF"
            border.color: Theme.border
            border.width: 1
        }

        Icon {
            anchors.left: parent.left
            anchors.leftMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            text: slider.glyph
            size: 12
            color: "#5B6B7B"
        }
    }

    MouseArea {
        anchors.fill: parent
        function update(x) {
            const v = Math.max(0, Math.min(1, x / width));
            slider.moved(v);
        }
        onPressed: m => update(m.x)
        onPositionChanged: m => { if (pressed) update(m.x); }
    }
}

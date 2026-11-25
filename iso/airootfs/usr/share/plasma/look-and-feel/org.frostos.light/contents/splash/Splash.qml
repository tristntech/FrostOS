// FrostOS splash screen, shown while the desktop loads after login.
// KSplash sets `stage` from 1 to 6 as Plasma starts up.
import QtQuick

Rectangle {
    id: root
    property int stage: 0

    gradient: Gradient {
        GradientStop { position: 0.0; color: "#0B1828" }
        GradientStop { position: 1.0; color: "#172B40" }
    }

    Column {
        anchors.centerIn: parent
        spacing: 22
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

        Image {
            id: logo
            anchors.horizontalCenter: parent.horizontalCenter
            source: "file:///usr/share/icons/hicolor/scalable/apps/frostos-logo.svg"
            sourceSize.width: 120
            sourceSize.height: 120
            RotationAnimation on rotation {
                from: 0; to: 360; duration: 9000; loops: Animation.Infinite
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "FrostOS"
            color: "#F8FCFF"
            font.family: "Inter"
            font.pixelSize: 30
            font.weight: Font.DemiBold
        }

        // Thin progress bar that fills as Plasma starts.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 180; height: 4; radius: 2
            color: "#24405E"
            Rectangle {
                width: parent.width * Math.min(root.stage, 6) / 6
                height: parent.height; radius: 2
                color: "#55AFFF"
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
    }
}

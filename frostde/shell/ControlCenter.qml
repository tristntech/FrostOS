// Control Center: quick switches and sliders, opened from the menu bar.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

PanelWindow {
    id: cc
    screen: Overlays.activeScreen
    visible: Overlays.controlCenterOpen

    anchors { top: true; right: true }
    margins { top: 6; right: 8 }
    exclusionMode: ExclusionMode.Normal
    implicitWidth: 330
    implicitHeight: panel.height
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "frostde-controlcenter"

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var adapter: Bluetooth.defaultAdapter
    PwObjectTracker { objects: cc.sink ? [cc.sink] : [] }

    // Screen brightness (only on screens with a backlight, e.g. laptops).
    property bool hasBacklight: false
    property real brightness: 1

    Process {
        id: readBrightness
        command: ["sh", "-c", "brightnessctl -m -c backlight 2>/dev/null | head -n 1"]
        stdout: StdioCollector {
            id: brightnessOut
            onStreamFinished: {
                // name,class,current,percent%,max
                const parts = brightnessOut.text.trim().split(",");
                cc.hasBacklight = parts.length >= 5;
                if (cc.hasBacklight)
                    cc.brightness = parseInt(parts[3]) / 100;
            }
        }
    }

    onVisibleChanged: {
        if (visible)
            readBrightness.running = true;
    }

    HyprlandFocusGrab {
        windows: [cc]
        active: cc.visible
        onCleared: Overlays.closeAll()
    }

    component Tile: Rectangle {
        id: tile
        property string glyph: ""
        property string title: ""
        property string subtitle: ""
        property bool isOn: false
        property bool available: true
        signal toggled()
        signal more()

        Layout.fillWidth: true
        implicitHeight: 58
        radius: Theme.radius
        color: Theme.tile
        border.color: Theme.border
        border.width: 1
        opacity: available ? 1 : 0.5

        Rectangle {
            id: circle
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: 17
            color: tile.isOn ? Theme.tileOn : Theme.hover
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Icon {
                anchors.centerIn: parent
                text: tile.glyph
                size: 14
                color: tile.isOn ? Theme.textOnAccent : Theme.text
            }
            MouseArea {
                anchors.fill: parent
                enabled: tile.available
                onClicked: tile.toggled()
            }
        }

        Column {
            anchors.left: circle.right
            anchors.leftMargin: 9
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            Label { width: parent.width; text: tile.title; font.weight: Font.DemiBold; font.pixelSize: 12 }
            Label { width: parent.width; text: tile.subtitle; secondary: true; font.pixelSize: 11 }
        }

        MouseArea {
            anchors.fill: parent
            anchors.leftMargin: 50
            onClicked: tile.more()
        }
    }

    Rectangle {
        id: panel
        width: parent.width
        height: layout.implicitHeight + 24
        radius: Theme.radiusLarge
        color: Theme.panel
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            GridLayout {
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                Layout.fillWidth: true

                Tile {
                    glyph: Glyphs.wifi
                    title: "Wi-Fi"
                    available: NetworkState.hasWifiDevice
                    isOn: NetworkState.wifiEnabled && NetworkState.hasWifiDevice
                    subtitle: !NetworkState.hasWifiDevice ? (NetworkState.wiredConnected ? "Using Ethernet" : "No Wi-Fi")
                            : !NetworkState.wifiEnabled ? "Off"
                            : NetworkState.wifiConnected ? NetworkState.wifiName : "Not Connected"
                    onToggled: NetworkState.setWifi(!NetworkState.wifiEnabled)
                    onMore: Overlays.openSettings("wifi")
                }

                Tile {
                    glyph: Glyphs.bluetooth
                    title: "Bluetooth"
                    available: cc.adapter !== null
                    isOn: cc.adapter !== null && cc.adapter.enabled
                    subtitle: cc.adapter === null ? "Not Available" : cc.adapter.enabled ? "On" : "Off"
                    onToggled: cc.adapter.enabled = !cc.adapter.enabled
                    onMore: Overlays.openSettings("bluetooth")
                }

                Tile {
                    glyph: Config.doNotDisturb ? Glyphs.bellSlash : Glyphs.bell
                    title: "Do Not Disturb"
                    isOn: Config.doNotDisturb
                    subtitle: Config.doNotDisturb ? "On" : "Off"
                    onToggled: Config.doNotDisturb = !Config.doNotDisturb
                    onMore: Config.doNotDisturb = !Config.doNotDisturb
                }

                Tile {
                    glyph: Config.dark ? Glyphs.moon : Glyphs.sun
                    title: "Dark Mode"
                    isOn: Config.dark
                    subtitle: Config.dark ? "On" : "Off"
                    onToggled: Config.appearance = Config.dark ? "light" : "dark"
                    onMore: Config.appearance = Config.dark ? "light" : "dark"
                }
            }

            Rectangle {
                visible: cc.hasBacklight
                Layout.fillWidth: true
                implicitHeight: displayCol.implicitHeight + 20
                radius: Theme.radius
                color: Theme.tile
                border.color: Theme.border
                border.width: 1
                Column {
                    id: displayCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Label { text: "Display"; font.weight: Font.DemiBold; font.pixelSize: 12 }
                    FrostSlider {
                        width: parent.width
                        glyph: Glyphs.sun
                        value: cc.brightness
                        onMoved: v => {
                            cc.brightness = Math.max(0.05, v);
                            Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set", Math.round(cc.brightness * 100) + "%"]);
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: soundCol.implicitHeight + 20
                radius: Theme.radius
                color: Theme.tile
                border.color: Theme.border
                border.width: 1
                Column {
                    id: soundCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Label { text: "Sound"; font.weight: Font.DemiBold; font.pixelSize: 12 }
                    FrostSlider {
                        width: parent.width
                        glyph: Glyphs.volumeHigh
                        value: cc.sink && cc.sink.audio ? (cc.sink.audio.muted ? 0 : cc.sink.audio.volume) : 0
                        onMoved: v => {
                            if (cc.sink && cc.sink.audio) {
                                cc.sink.audio.muted = false;
                                cc.sink.audio.volume = v;
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.radius
                color: settingsMouse.containsMouse ? Theme.hover : Theme.tile
                border.color: Theme.border
                border.width: 1
                Label {
                    anchors.centerIn: parent
                    text: "Open Frost Settings…"
                }
                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Overlays.openSettings()
                }
            }
        }
    }
}

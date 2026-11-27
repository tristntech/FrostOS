// The menu bar at the top of each screen.
//   left:  FrostOS menu | app name | Window | Help
//   right: battery | network | volume | Spotlight | Control Center | date and time
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.menuBarHeight
    exclusiveZone: Theme.menuBarHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "frostde-menubar"

    readonly property var activeWindow: ToplevelManager.activeToplevel
    readonly property string activeAppId: activeWindow ? activeWindow.appId : "org.gnome.Nautilus"
    readonly property string activeAppName: Apps.name(activeAppId)

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: bar.sink ? [bar.sink] : [] }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.menuBar
        Behavior on color { ColorAnimation { duration: Theme.animSlow } }
    }

    // ---------------------------------------------------------- left side
    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        BarButton {
            id: logoButton
            active: frostMenu.visible
            onClicked: frostMenu.toggle()
            IconImage {
                source: Quickshell.iconPath("frostos-logo")
                implicitSize: 16
            }
        }

        BarButton {
            id: appButton
            text: bar.activeAppName
            bold: true
            active: appMenu.visible
            onClicked: appMenu.toggle()
        }

        BarButton {
            id: windowButton
            text: "Window"
            active: windowMenu.visible
            onClicked: windowMenu.toggle()
        }

        BarButton {
            id: helpButton
            text: "Help"
            active: helpMenu.visible
            onClicked: helpMenu.toggle()
        }
    }

    // --------------------------------------------------------- right side
    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        BarButton {
            visible: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
            readonly property real level: {
                const p = UPower.displayDevice.percentage;
                return p > 1 ? p / 100 : p;      // handle both 0-1 and 0-100
            }
            text: Math.round(level * 100) + "%"
            glyph: level > 0.85 ? Glyphs.battery100 : level > 0.6 ? Glyphs.battery75
                 : level > 0.35 ? Glyphs.battery50 : level > 0.12 ? Glyphs.battery25 : Glyphs.battery0
            glyphSize: 15
            onClicked: Overlays.openSettings("battery")
        }

        BarButton {
            glyph: NetworkState.wifiConnected || !NetworkState.wiredConnected ? Glyphs.wifi : Glyphs.desktop
            opacity: NetworkState.wifiConnected || NetworkState.wiredConnected ? 1 : 0.4
            onClicked: Overlays.toggleControlCenter()
        }

        BarButton {
            readonly property var audio: bar.sink ? bar.sink.audio : null
            glyph: !audio || audio.muted || audio.volume <= 0.001 ? Glyphs.volumeOff
                 : audio.volume < 0.5 ? Glyphs.volumeLow : Glyphs.volumeHigh
            onClicked: Overlays.toggleControlCenter()
        }

        BarButton {
            glyph: Glyphs.search
            glyphSize: 13
            active: Overlays.spotlightOpen
            onClicked: Overlays.toggleSpotlight()
        }

        BarButton {
            glyph: Glyphs.sliders
            glyphSize: 13
            active: Overlays.controlCenterOpen
            onClicked: Overlays.toggleControlCenter()
        }

        BarButton {
            text: Qt.formatDateTime(clock.date, Config.clock24h ? "ddd d MMM   HH:mm" : "ddd d MMM   h:mm AP")
            active: Overlays.notificationCenterOpen
            onClicked: Overlays.toggleNotificationCenter()
        }
    }

    // -------------------------------------------------------------- menus
    FrostMenu {
        id: frostMenu
        anchorItem: logoButton
        ownerWindow: bar
        items: [
            { text: "About This Computer", action: () => Overlays.openSettings("about") },
            { separator: true },
            { text: "System Settings…", action: () => Overlays.openSettings() },
            { text: "Frost Store…", action: () => Overlays.run("gnome-software") },
            { separator: true },
            { text: "Force Quit App", enabled: bar.activeWindow !== null,
              action: () => Apps.dispatch(["hl.dsp.window.kill()"]) },
            { separator: true },
            { text: "Sleep", action: () => Overlays.run("systemctl suspend") },
            { text: "Restart…", action: () => Overlays.run("systemctl reboot") },
            { text: "Shut Down…", action: () => Overlays.run("systemctl poweroff") },
            { separator: true },
            { text: "Lock Screen", hint: "Super L", action: () => Overlays.run("frostde-lock") },
            { text: "Log Out", hint: "Super Shift Q", action: () => Overlays.run("frostde-logout") }
        ]
    }

    FrostMenu {
        id: appMenu
        anchorItem: appButton
        ownerWindow: bar
        items: [
            { text: "New " + bar.activeAppName + " Window", action: () => Apps.launch(bar.activeAppId) },
            { separator: true },
            { text: "Hide " + bar.activeAppName, enabled: bar.activeWindow !== null,
              action: () => Apps.windows(bar.activeAppId).forEach(w => Apps.minimize(w)) },
            { text: Apps.isPinned(bar.activeAppId) ? "Remove from Dock" : "Keep in Dock",
              action: () => Apps.isPinned(bar.activeAppId) ? Apps.unpin(bar.activeAppId) : Apps.pin(bar.activeAppId) },
            { separator: true },
            { text: "Quit " + bar.activeAppName, hint: "Super Q", enabled: bar.activeWindow !== null,
              action: () => Apps.quit(bar.activeAppId) }
        ]
    }

    FrostMenu {
        id: windowMenu
        anchorItem: windowButton
        ownerWindow: bar
        items: [
            { text: "Minimize", hint: "Super M", enabled: bar.activeWindow !== null,
              action: () => Apps.minimize(bar.activeWindow) },
            { text: "Zoom", enabled: bar.activeWindow !== null,
              action: () => Apps.toggleMaximize(bar.activeWindow) },
            { text: "Center", enabled: bar.activeWindow !== null,
              action: () => Apps.centerWindow(bar.activeWindow) },
            { text: "Enter Full Screen", hint: "Super F", enabled: bar.activeWindow !== null,
              action: () => Apps.toggleFullscreen(bar.activeWindow) },
            { separator: true },
            { text: "Close Window", hint: "Super W", enabled: bar.activeWindow !== null,
              action: () => bar.activeWindow.close() }
        ]
    }

    FrostMenu {
        id: helpMenu
        anchorItem: helpButton
        ownerWindow: bar
        items: [
            { text: "Keyboard Shortcuts", action: () => Overlays.openSettings("keyboard") },
            { text: "FrostOS Help", action: () => Overlays.run("xdg-open https://github.com/tristntech/FrostOS#readme") }
        ]
    }
}

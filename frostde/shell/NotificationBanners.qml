// Notification banners in the top-right corner. Each one disappears after a
// few seconds but stays in the Notification Center.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    screen: Overlays.activeScreen
    visible: Notifs.banners.length > 0 && !Overlays.notificationCenterOpen && !Overlays.controlCenterOpen
             && !Overlays.launchpadOpen && !Overlays.spotlightOpen

    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    margins { top: Theme.menuBarHeight + 4; right: 10 }
    implicitWidth: 360
    implicitHeight: Math.max(1, stack.height + 8)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "frostde-notifications"

    Column {
        id: stack
        x: 6
        y: 6
        width: parent.width - 12
        spacing: 8

        Repeater {
            model: Notifs.banners

            delegate: NotificationCard {
                id: banner
                required property var modelData
                notification: modelData
                width: stack.width
                onCloseRequested: modelData.dismiss()

                Timer {
                    running: true
                    interval: banner.modelData.expireTimeout > 0
                              ? Math.min(banner.modelData.expireTimeout * 1000, 10000) : 5000
                    onTriggered: Notifs.hideBanner(banner.modelData)
                }

                Connections {
                    target: banner.modelData
                    function onClosed() {
                        Notifs.hideBanner(banner.modelData);
                    }
                }
            }
        }
    }
}

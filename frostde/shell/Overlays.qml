// Which FrostDE overlays are open (Launchpad, Spotlight, Control Center,
// Notification Center). Only one is open at a time, like on a Mac.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property bool launchpadOpen: false
    property bool spotlightOpen: false
    property bool controlCenterOpen: false
    property bool notificationCenterOpen: false

    // The screen the user is working on.
    readonly property var activeScreen: {
        const mon = Hyprland.focusedMonitor;
        if (mon) {
            for (const s of Quickshell.screens) {
                if (s.name === mon.name)
                    return s;
            }
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function closeAll() {
        launchpadOpen = false;
        spotlightOpen = false;
        controlCenterOpen = false;
        notificationCenterOpen = false;
    }

    function toggleLaunchpad() {
        const open = !launchpadOpen;
        closeAll();
        launchpadOpen = open;
    }

    function toggleSpotlight() {
        const open = !spotlightOpen;
        closeAll();
        spotlightOpen = open;
    }

    function toggleControlCenter() {
        const open = !controlCenterOpen;
        closeAll();
        controlCenterOpen = open;
    }

    function toggleNotificationCenter() {
        const open = !notificationCenterOpen;
        closeAll();
        notificationCenterOpen = open;
    }

    function openSettings(page) {
        closeAll();
        Quickshell.execDetached(page ? ["frost-settings", "--page", page] : ["frost-settings"]);
    }

    function run(command) {
        closeAll();
        Quickshell.execDetached(["sh", "-c", command]);
    }
}

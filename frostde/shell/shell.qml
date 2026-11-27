// FrostDE shell: everything you see around your windows.
// Started by Hyprland (see /usr/share/frostde/hyprland.lua) with:
//     qs -p /usr/share/frostde/shell
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    // One wallpaper, menu bar and dock per screen.
    Variants {
        model: Quickshell.screens
        Wallpaper {}
    }
    Variants {
        model: Quickshell.screens
        MenuBar {}
    }
    Variants {
        model: Quickshell.screens
        Dock {}
    }

    Launchpad {}
    Spotlight {}
    ControlCenter {}
    NotificationCenter {}
    NotificationBanners {}

    // Keyboard shortcuts. Hyprland sends these keys here, see hyprland.lua.
    GlobalShortcut {
        appid: "frostde"
        name: "spotlight"
        description: "Open Spotlight search"
        onPressed: Overlays.toggleSpotlight()
    }
    GlobalShortcut {
        appid: "frostde"
        name: "launchpad"
        description: "Open Launchpad"
        onPressed: Overlays.toggleLaunchpad()
    }
    GlobalShortcut {
        appid: "frostde"
        name: "controlcenter"
        description: "Open Control Center"
        onPressed: Overlays.toggleControlCenter()
    }
    GlobalShortcut {
        appid: "frostde"
        name: "notifications"
        description: "Open Notification Center"
        onPressed: Overlays.toggleNotificationCenter()
    }
    GlobalShortcut {
        appid: "frostde"
        name: "close-overlays"
        description: "Close FrostDE overlays"
        onPressed: Overlays.closeAll()
    }

    // Commands other programs can send, e.g.
    //     qs -p /usr/share/frostde/shell ipc call frostde launchpad
    IpcHandler {
        target: "frostde"
        function spotlight(): void { Overlays.toggleSpotlight(); }
        function launchpad(): void { Overlays.toggleLaunchpad(); }
        function controlCenter(): void { Overlays.toggleControlCenter(); }
        function notifications(): void { Overlays.toggleNotificationCenter(); }
    }

    // Keep GTK apps (Files, Terminal, ...) in the same light/dark mode as FrostDE.
    function applyColorScheme() {
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme",
                                 Config.dark ? "prefer-dark" : "default"]);
        // Older GTK 3 apps use a separate dark theme.
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme",
                                 Config.dark ? "adw-gtk3-dark" : "adw-gtk3"]);
    }

    Connections {
        target: Config
        function onAppearanceChanged() {
            root.applyColorScheme();
        }
    }

    // Make sure the notification service starts with the shell.
    Component.onCompleted: {
        Notifs.banners;
        NetworkState.wifiEnabled;
        applyColorScheme();
    }
}

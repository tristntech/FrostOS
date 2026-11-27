// FrostDE settings, shared by the shell and Frost Settings.
// Stored as JSON in ~/.config/frostde/settings.json. frostde-session creates
// that file from /usr/share/frostde/settings.json on first login.
// Both programs watch the file, so a change in one shows up in the other.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/frostde/settings.json"

    property alias appearance: adapter.appearance          // "light" or "dark"
    property alias accent: adapter.accent                  // color as "#RRGGBB"
    property alias wallpaperLight: adapter.wallpaperLight
    property alias wallpaperDark: adapter.wallpaperDark
    property alias dockSize: adapter.dockSize              // icon size in px
    property alias dockMagnification: adapter.dockMagnification
    property alias dockMagnifiedSize: adapter.dockMagnifiedSize
    property alias dockAutohide: adapter.dockAutohide
    property alias pinnedApps: adapter.pinnedApps          // desktop file ids, without ".desktop"
    property alias clock24h: adapter.clock24h
    property alias doNotDisturb: adapter.doNotDisturb
    property alias reduceMotion: adapter.reduceMotion

    readonly property bool dark: appearance === "dark"

    FileView {
        id: file
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        // A change made in the shell (e.g. the Dark Mode switch) is saved straight away.
        onAdapterUpdated: writeAdapter()
        // No file yet (or it is broken): write the defaults.
        onLoadFailed: writeAdapter()

        JsonAdapter {
            id: adapter
            property string appearance: "light"
            property string accent: "#55AFFF"
            property string wallpaperLight: "/usr/share/backgrounds/frostos/frost-light.png"
            property string wallpaperDark: "/usr/share/backgrounds/frostos/frost-dark.png"
            property int dockSize: 52
            property bool dockMagnification: true
            property int dockMagnifiedSize: 84
            property bool dockAutohide: false
            property list<string> pinnedApps: [
                "org.gnome.Nautilus",
                "brave-browser",
                "org.gnome.Ptyxis",
                "org.gnome.Software",
                "org.frostos.Settings"
            ]
            property bool clock24h: false
            property bool doNotDisturb: false
            property bool reduceMotion: false
        }
    }
}

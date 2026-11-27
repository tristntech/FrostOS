// FrostDE look: colors, fonts, sizes and animation speeds.
// Colors follow the FrostOS palette (see info.md) in light and dark mode.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property bool dark: Config.dark
    readonly property color accent: Config.accent

    // Frosted surfaces. They are see-through; Hyprland blurs what is behind them.
    readonly property color menuBar:   dark ? Qt.rgba(0.05, 0.10, 0.16, 0.50) : Qt.rgba(0.97, 0.99, 1.00, 0.55)
    readonly property color dock:      dark ? Qt.rgba(0.08, 0.13, 0.20, 0.55) : Qt.rgba(0.97, 0.99, 1.00, 0.50)
    readonly property color panel:     dark ? Qt.rgba(0.09, 0.14, 0.21, 0.80) : Qt.rgba(0.97, 0.99, 1.00, 0.80)
    readonly property color tile:      dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.70)
    readonly property color tileOn:    accent
    readonly property color border:    dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0.09, 0.17, 0.25, 0.10)
    readonly property color hover:     dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0.09, 0.17, 0.25, 0.07)
    readonly property color separator: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0.09, 0.17, 0.25, 0.12)
    readonly property color shade:     Qt.rgba(0.03, 0.07, 0.12, dark ? 0.45 : 0.25)

    readonly property color text:          dark ? "#E8F1F8" : "#172B40"
    readonly property color textSecondary: dark ? "#9AB0C4" : "#71869A"
    readonly property color textOnAccent:  "#FFFFFF"

    readonly property string font: "Inter"
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property int fontSize: 13

    readonly property int menuBarHeight: 30
    readonly property int radius: 12
    readonly property int radiusLarge: 18

    // Animation speeds; all become 0 with "Reduce motion".
    readonly property int animFast:   Config.reduceMotion ? 0 : 120
    readonly property int animNormal: Config.reduceMotion ? 0 : 220
    readonly property int animSlow:   Config.reduceMotion ? 0 : 350
}

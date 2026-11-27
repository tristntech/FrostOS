// Icon glyphs from the "Symbols Nerd Font" (Font Awesome set).
// Using a font means the icons follow the text color in light and dark mode.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string wifi:        String.fromCodePoint(0xF1EB)
    readonly property string bluetooth:   String.fromCodePoint(0xF294)
    readonly property string volumeHigh:  String.fromCodePoint(0xF028)
    readonly property string volumeLow:   String.fromCodePoint(0xF027)
    readonly property string volumeOff:   String.fromCodePoint(0xF026)
    readonly property string battery100:  String.fromCodePoint(0xF240)
    readonly property string battery75:   String.fromCodePoint(0xF241)
    readonly property string battery50:   String.fromCodePoint(0xF242)
    readonly property string battery25:   String.fromCodePoint(0xF243)
    readonly property string battery0:    String.fromCodePoint(0xF244)
    readonly property string bolt:        String.fromCodePoint(0xF0E7)
    readonly property string search:      String.fromCodePoint(0xF002)
    readonly property string sliders:     String.fromCodePoint(0xF1DE)
    readonly property string moon:        String.fromCodePoint(0xF186)
    readonly property string sun:         String.fromCodePoint(0xF185)
    readonly property string bell:        String.fromCodePoint(0xF0F3)
    readonly property string bellSlash:   String.fromCodePoint(0xF1F6)
    readonly property string power:       String.fromCodePoint(0xF011)
    readonly property string lock:        String.fromCodePoint(0xF023)
    readonly property string gear:        String.fromCodePoint(0xF013)
    readonly property string close:       String.fromCodePoint(0xF00D)
    readonly property string desktop:     String.fromCodePoint(0xF108)
    readonly property string globe:       String.fromCodePoint(0xF0AC)
    readonly property string calculator:  String.fromCodePoint(0xF1EC)
}

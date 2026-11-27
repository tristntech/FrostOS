// A small monochrome icon (a glyph from the icon font, see Glyphs.qml).
import QtQuick

Text {
    property real size: 14
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}

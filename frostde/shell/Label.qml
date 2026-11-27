// Text in the FrostDE font and colors.
import QtQuick

Text {
    property bool secondary: false
    color: secondary ? Theme.textSecondary : Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}

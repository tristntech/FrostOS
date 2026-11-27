// Spotlight: press Super+Space, type, press Enter.
// Finds apps, works out simple sums (like 12*7), and can search the web.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

PanelWindow {
    id: spot
    screen: Overlays.activeScreen
    visible: Overlays.spotlightOpen

    anchors.top: true
    margins.top: screen ? Math.round(screen.height * 0.2) : 160
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 660
    implicitHeight: box.height
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "frostde-spotlight"
    WlrLayershell.keyboardFocus: Overlays.spotlightOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string query: ""
    property int selected: 0

    // A sum, if the text is one (only digits, + - * / % ( ) . and spaces).
    readonly property string sum: {
        const q = query.trim();
        if (!/^[0-9+\-*/%(). ]+$/.test(q) || !/[0-9]/.test(q) || !/[+\-*/%]/.test(q))
            return "";
        try {
            const value = Function("return (" + q + ");")();
            return (typeof value === "number" && isFinite(value)) ? String(Math.round(value * 1e10) / 1e10) : "";
        } catch (e) {
            return "";
        }
    }

    readonly property var results: {
        const q = query.trim().toLowerCase();
        if (q === "")
            return [];
        const out = [];
        if (sum !== "")
            out.push({ kind: "sum", title: sum, subtitle: query.trim() + " =", glyph: Glyphs.calculator });
        const apps = DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .map(e => {
                const name = e.name.toLowerCase();
                const score = name.startsWith(q) ? 0
                            : name.includes(q) ? 1
                            : (e.genericName || "").toLowerCase().includes(q) ? 2
                            : e.keywords.some(k => k.toLowerCase().includes(q)) ? 3 : -1;
                return { entry: e, score: score };
            })
            .filter(r => r.score >= 0)
            .sort((a, b) => a.score - b.score || a.entry.name.localeCompare(b.entry.name))
            .slice(0, 6);
        for (const r of apps)
            out.push({ kind: "app", title: r.entry.name, subtitle: r.entry.genericName || "Application", entry: r.entry });
        out.push({ kind: "web", title: "Search the web for “" + query.trim() + "”", subtitle: "Brave Search", glyph: Glyphs.globe });
        return out;
    }

    function run(result) {
        if (!result)
            return;
        if (result.kind === "app")
            result.entry.execute();
        else if (result.kind === "web")
            Quickshell.execDetached(["xdg-open", "https://search.brave.com/search?q=" + encodeURIComponent(query.trim())]);
        else if (result.kind === "sum")
            Quickshell.clipboardText = result.title;
        Overlays.closeAll();
    }

    onVisibleChanged: {
        if (visible) {
            input.text = "";
            selected = 0;
            input.forceActiveFocus();
        }
    }

    HyprlandFocusGrab {
        windows: [spot]
        active: spot.visible
        onCleared: Overlays.closeAll()
    }

    Rectangle {
        id: box
        width: parent.width
        height: column.height
        radius: Theme.radiusLarge
        color: Theme.panel
        border.color: Theme.border
        border.width: 1
        opacity: Overlays.spotlightOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

        Column {
            id: column
            width: parent.width

            Item {
                width: parent.width
                height: 56

                Icon {
                    id: lens
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: Glyphs.search
                    size: 18
                    color: Theme.textSecondary
                }

                TextInput {
                    id: input
                    anchors.left: lens.right
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 22
                    clip: true
                    onTextChanged: {
                        spot.query = text;
                        spot.selected = 0;
                    }
                    Keys.onEscapePressed: Overlays.closeAll()
                    Keys.onReturnPressed: spot.run(spot.results[spot.selected])
                    Keys.onDownPressed: spot.selected = Math.min(spot.selected + 1, spot.results.length - 1)
                    Keys.onUpPressed: spot.selected = Math.max(spot.selected - 1, 0)

                    Label {
                        visible: input.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Spotlight Search"
                        secondary: true
                        font.pixelSize: 22
                    }
                }
            }

            Rectangle {
                visible: spot.results.length > 0
                width: parent.width
                height: 1
                color: Theme.separator
            }

            Column {
                visible: spot.results.length > 0
                width: parent.width
                topPadding: 6
                bottomPadding: 6

                Repeater {
                    model: spot.results

                    delegate: Item {
                        id: result
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 48

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            radius: 8
                            color: spot.selected === result.index ? Theme.accent : "transparent"
                        }

                        IconImage {
                            id: resultIcon
                            visible: result.modelData.kind === "app"
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 32
                            source: result.modelData.kind === "app"
                                    ? Quickshell.iconPath(result.modelData.entry.icon, "application-x-executable") : ""
                        }

                        Icon {
                            visible: result.modelData.kind !== "app"
                            anchors.centerIn: resultIcon
                            text: result.modelData.glyph || ""
                            size: 20
                            color: spot.selected === result.index ? Theme.textOnAccent : Theme.textSecondary
                        }

                        Column {
                            anchors.left: resultIcon.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.verticalCenter: parent.verticalCenter

                            Label {
                                width: parent.width
                                text: result.modelData.title
                                font.pixelSize: 15
                                color: spot.selected === result.index ? Theme.textOnAccent : Theme.text
                            }
                            Label {
                                width: parent.width
                                text: result.modelData.subtitle
                                font.pixelSize: 12
                                color: spot.selected === result.index ? Theme.textOnAccent : Theme.textSecondary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: spot.selected = result.index
                            onClicked: spot.run(result.modelData)
                        }
                    }
                }
            }
        }
    }
}

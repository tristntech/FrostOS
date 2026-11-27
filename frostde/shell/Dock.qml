// The Dock: Launchpad, pinned and open apps, then the Trash.
// Icons grow as the pointer moves over them (magnification), open apps get a
// dot underneath, and right-clicking an icon shows a small menu.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: dock
    required property var modelData
    screen: modelData

    // ---- sizes ----
    readonly property int base: Config.dockSize
    readonly property int big: Config.dockMagnification ? Math.max(Config.dockMagnifiedSize, base) : base
    readonly property int pad: 7                 // space between icons and the dock edge
    readonly property int gap: 6                 // space between icons
    readonly property int edge: 6                // space below the dock
    readonly property int separatorWidth: 13
    readonly property int barHeight: base + pad * 2

    // ---- state ----
    property real pointerX: -1                   // pointer x in this window, -1 = not over the dock
    property int hoveredIndex: -1
    readonly property bool menuOpen: contextMenu.visible
    readonly property bool hidden: Config.dockAutohide && !hoverArea.containsMouse && !menuOpen

    anchors { bottom: true; left: true; right: true }
    implicitHeight: big + pad * 2 + edge + 40    // room for magnified icons and the name label
    exclusiveZone: Config.dockAutohide ? 0 : barHeight + edge
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "frostde-dock"

    // Only the dock itself takes clicks; the rest of this window lets them through.
    mask: Region { item: hitArea }

    // ---- what is in the dock ----
    readonly property var items: {
        const list = [{ kind: "launchpad" }];
        for (const id of Config.pinnedApps)
            list.push({ kind: "app", appId: id });
        for (const id of Apps.runningApps) {
            if (!Apps.isPinned(id))
                list.push({ kind: "app", appId: id });
        }
        list.push({ kind: "separator" });
        list.push({ kind: "trash" });
        return list;
    }

    function baseWidth(item) {
        return item.kind === "separator" ? separatorWidth : base;
    }

    // Centers of the icons when nothing is magnified. Magnification is worked
    // out from these, so the icons don't jump around while they grow.
    readonly property var baseCenters: {
        let total = 0;
        for (const it of items)
            total += baseWidth(it);
        total += gap * (items.length - 1);
        const out = [];
        let x = (width - total) / 2;
        for (const it of items) {
            const w = baseWidth(it);
            out.push(x + w / 2);
            x += w + gap;
        }
        return out;
    }

    function sizeFor(index) {
        if (pointerX < 0 || big <= base)
            return base;
        const range = base * 2.8;
        const d = Math.abs(pointerX - baseCenters[index]);
        if (d >= range)
            return base;
        return base + (big - base) * Math.cos(d / range * Math.PI / 2);
    }

    function indexAt(x) {
        for (let i = 0; i < icons.count; i++) {
            const it = icons.itemAt(i);
            if (!it)
                continue;
            const p = it.mapToItem(body, 0, 0);
            if (x >= p.x - gap / 2 && x <= p.x + it.width + gap / 2)
                return i;
        }
        return -1;
    }

    function activate(index) {
        const item = items[index];
        if (!item)
            return;
        if (item.kind === "launchpad") {
            Overlays.toggleLaunchpad();
        } else if (item.kind === "trash") {
            Overlays.run("nautilus trash:///");
        } else if (item.kind === "app") {
            Overlays.closeAll();
            if (Apps.windows(item.appId).length === 0) {
                const icon = icons.itemAt(index);
                if (icon)
                    icon.bounce();
            }
            Apps.activate(item.appId);
        }
    }

    function openMenu(index) {
        const item = items[index];
        if (!item || item.kind === "launchpad" || item.kind === "separator")
            return;
        let menuItems = [];
        if (item.kind === "trash") {
            menuItems = [
                { text: "Open", action: () => Overlays.run("nautilus trash:///") },
                { separator: true },
                { text: "Empty Trash", action: () => Overlays.run("gio trash --empty") }
            ];
        } else {
            const running = Apps.windows(item.appId).length > 0;
            const pinned = Apps.isPinned(item.appId);
            menuItems = [
                { text: running ? "New Window" : "Open", action: () => Apps.launch(item.appId) },
                { separator: true },
                { text: pinned ? "Remove from Dock" : "Keep in Dock",
                  action: () => pinned ? Apps.unpin(item.appId) : Apps.pin(item.appId) }
            ];
            if (running)
                menuItems.push({ separator: true }, { text: "Quit", action: () => Apps.quit(item.appId) });
        }
        contextMenu.items = menuItems;
        contextMenu.anchorItem = icons.itemAt(index);
        contextMenu.open();
    }

    // ---- the part of the window that reacts to the pointer ----
    Item {
        id: hitArea
        readonly property real bgWidth: background.width
        x: (dock.width - bgWidth) / 2
        width: bgWidth
        height: dock.hidden ? 4
              : (hoverArea.containsMouse || dock.menuOpen) ? dock.height
              : dock.barHeight + dock.edge
        anchors.bottom: parent.bottom
    }

    MouseArea {
        id: hoverArea
        anchors.fill: hitArea
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPositionChanged: m => {
            const p = mapToItem(body, m.x, m.y);
            dock.pointerX = p.x;
            dock.hoveredIndex = dock.indexAt(p.x);
        }
        onExited: {
            dock.pointerX = -1;
            dock.hoveredIndex = -1;
        }
        onClicked: m => {
            const p = mapToItem(body, m.x, m.y);
            const i = dock.indexAt(p.x);
            if (m.button === Qt.RightButton)
                dock.openMenu(i);
            else
                dock.activate(i);
        }
    }

    // ---- what you see ----
    Item {
        id: body
        width: dock.width
        height: dock.height
        y: dock.hidden ? dock.barHeight + dock.edge + 6 : 0
        Behavior on y { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

        Rectangle {
            id: background
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: dock.edge
            width: row.width + dock.pad * 2
            height: dock.barHeight
            radius: Theme.radiusLarge
            color: Theme.dock
            border.color: Theme.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: Theme.animSlow } }
        }

        Row {
            id: row
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: dock.edge + dock.pad
            spacing: dock.gap

            Repeater {
                id: icons
                model: dock.items

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool isSeparator: modelData.kind === "separator"
                    readonly property real size: isSeparator ? dock.base : dock.sizeFor(index)
                    readonly property bool running: modelData.kind === "app" && Apps.windows(modelData.appId).length > 0
                    property real lift: 0

                    function bounce() {
                        if (Theme.animNormal > 0)
                            bounceAnim.restart();
                    }

                    width: isSeparator ? dock.separatorWidth : size
                    height: size
                    anchors.bottom: parent.bottom

                    Behavior on width { enabled: dock.pointerX < 0; NumberAnimation { duration: Theme.animFast } }
                    Behavior on height { enabled: dock.pointerX < 0; NumberAnimation { duration: Theme.animFast } }

                    Rectangle {
                        visible: cell.isSeparator
                        anchors.centerIn: parent
                        width: 1
                        height: dock.base * 0.75
                        color: Theme.separator
                    }

                    IconImage {
                        visible: !cell.isSeparator
                        anchors.fill: parent
                        transform: Translate { y: -cell.lift }
                        mipmap: true
                        source: cell.modelData.kind === "launchpad" ? Quickshell.iconPath("frostos-launchpad")
                              : cell.modelData.kind === "trash" ? Quickshell.iconPath("user-trash", "user-trash-full")
                              : cell.modelData.kind === "app" ? Apps.icon(cell.modelData.appId) : ""
                    }

                    // Open-app dot
                    Rectangle {
                        visible: cell.running
                        width: 4
                        height: 4
                        radius: 2
                        color: Theme.text
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 2
                    }

                    // Name label above the hovered icon
                    Rectangle {
                        visible: dock.hoveredIndex === cell.index && !cell.isSeparator && !dock.menuOpen
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 8
                        width: tip.implicitWidth + 20
                        height: 24
                        radius: 7
                        color: Theme.panel
                        border.color: Theme.border
                        border.width: 1
                        Label {
                            id: tip
                            anchors.centerIn: parent
                            text: cell.modelData.kind === "launchpad" ? "Launchpad"
                                : cell.modelData.kind === "trash" ? "Trash"
                                : cell.modelData.kind === "app" ? Apps.name(cell.modelData.appId) : ""
                        }
                    }

                    SequentialAnimation {
                        id: bounceAnim
                        loops: 2
                        NumberAnimation { target: cell; property: "lift"; to: dock.base * 0.45; duration: 260; easing.type: Easing.OutQuad }
                        NumberAnimation { target: cell; property: "lift"; to: 0; duration: 260; easing.type: Easing.InQuad }
                    }
                }
            }
        }
    }

    FrostMenu {
        id: contextMenu
        opensUp: true
        ownerWindow: dock
    }
}

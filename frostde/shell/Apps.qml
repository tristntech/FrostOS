// Apps and windows: find an app's name and icon, launch it, switch to its
// windows, minimize and restore them.
//
// Minimizing: Hyprland has no "minimized" state, so FrostDE parks minimized
// windows on a hidden workspace called "special:minimized" and brings them
// back from the dock.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Singleton {
    id: root

    // The .desktop entry for an app id (a window's app id or a desktop file id).
    function entry(appId) {
        if (!appId)
            return null;
        let e = DesktopEntries.byId(appId);
        if (!e)
            e = DesktopEntries.byId(appId.toLowerCase());
        if (!e)
            e = DesktopEntries.heuristicLookup(appId);
        return e;
    }

    function name(appId) {
        const e = entry(appId);
        if (e)
            return e.name;
        // No .desktop file: turn "org.example.MyApp" into "MyApp".
        const last = (appId || "").split(".").pop();
        return last.charAt(0).toUpperCase() + last.slice(1);
    }

    function icon(appId) {
        const e = entry(appId);
        return Quickshell.iconPath(e && e.icon ? e.icon : (appId || ""), "application-x-executable");
    }

    function sameApp(a, b) {
        if (!a || !b)
            return false;
        if (a.toLowerCase() === b.toLowerCase())
            return true;
        const ea = entry(a);
        const eb = entry(b);
        return ea !== null && eb !== null && ea.id === eb.id;
    }

    // All open windows of an app.
    function windows(appId) {
        return ToplevelManager.toplevels.values.filter(t => sameApp(t.appId, appId));
    }

    // App ids that have open windows, one per app, in the order they opened.
    readonly property var runningApps: {
        const ids = [];
        for (const t of ToplevelManager.toplevels.values) {
            if (t.appId && !ids.some(i => sameApp(i, t.appId)))
                ids.push(t.appId);
        }
        return ids;
    }

    function isPinned(appId) {
        return Config.pinnedApps.some(p => sameApp(p, appId));
    }

    function pin(appId) {
        if (isPinned(appId))
            return;
        const e = entry(appId);
        const id = e ? e.id.replace(/\.desktop$/, "") : appId;
        Config.pinnedApps = Config.pinnedApps.concat([id]);
    }

    function unpin(appId) {
        Config.pinnedApps = Config.pinnedApps.filter(p => !sameApp(p, appId));
    }

    function launch(appId) {
        const e = entry(appId);
        if (e)
            e.execute();
    }

    function quit(appId) {
        for (const w of windows(appId))
            w.close();
    }

    // Dock click: open the app, or bring its windows forward, or restore them.
    function activate(appId) {
        const wins = windows(appId);
        if (wins.length === 0) {
            launch(appId);
            return;
        }
        const shown = wins.filter(w => !isMinimized(w));
        if (shown.length > 0)
            shown[shown.length - 1].activate();
        else
            restore(wins[wins.length - 1]);
    }

    // ---- Hyprland helpers ----------------------------------------------

    function hyprWindow(toplevel) {
        for (const h of Hyprland.toplevels.values) {
            if (h.wayland === toplevel)
                return h;
        }
        return null;
    }

    function selector(toplevel) {
        const h = hyprWindow(toplevel);
        if (!h || !h.address)
            return null;
        return "address:" + (h.address.startsWith("0x") ? h.address : "0x" + h.address);
    }

    function isMinimized(toplevel) {
        const h = hyprWindow(toplevel);
        return h !== null && h.workspace !== null && h.workspace.name === "special:minimized";
    }

    // Runs Hyprland dispatchers (Lua expressions, because FrostDE's Hyprland
    // config is written in Lua) one after the other.
    function dispatch(commands) {
        const quote = s => "'" + s.replace(/'/g, "'\\''") + "'";
        const script = commands.map(c => "hyprctl dispatch " + quote(c)).join(" && ");
        Quickshell.execDetached(["sh", "-c", script]);
    }

    function minimize(toplevel) {
        const sel = selector(toplevel);
        if (sel)
            dispatch([`hl.dsp.window.move({ window = "${sel}", workspace = "special:minimized", follow = false })`]);
    }

    function restore(toplevel) {
        const sel = selector(toplevel);
        const ws = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1;
        if (sel)
            dispatch([
                `hl.dsp.window.move({ window = "${sel}", workspace = ${ws}, follow = true })`,
                `hl.dsp.focus({ window = "${sel}" })`
            ]);
    }

    function toggleMaximize(toplevel) {
        const sel = selector(toplevel);
        if (sel)
            dispatch([`hl.dsp.window.fullscreen({ window = "${sel}", mode = "maximized", action = "toggle" })`]);
    }

    function toggleFullscreen(toplevel) {
        const sel = selector(toplevel);
        if (sel)
            dispatch([`hl.dsp.window.fullscreen({ window = "${sel}", mode = "fullscreen", action = "toggle" })`]);
    }

    function centerWindow(toplevel) {
        const sel = selector(toplevel);
        if (sel)
            dispatch([`hl.dsp.window.center({ window = "${sel}" })`]);
    }
}

// FrostOS default desktop layout.
//
// Plasma runs this once, the first time a user logs in (and again only if the
// user picks "Use desktop layout from theme" in Settings > Global Theme).
// It builds:
//   - a top menu bar:  FrostOS menu | app menu | ...space... | status icons | clock
//   - a bottom dock:   Launchpad | pinned + running apps | Trash
//
// The wallpaper comes from contents/defaults ([Wallpaper] Image=FrostOS).

// Adds a widget to a panel and writes its settings.
// `config` looks like { "General": { "icon": "frostos-logo" } }.
// If a widget is missing (for example a future Plasma renamed it) we log it and
// carry on, so one missing widget never leaves the user with no panels at all.
function addFrostWidget(panel, plugin, config) {
    var widget = null;
    try {
        widget = panel.addWidget(plugin);
    } catch (e) {
        print("FrostOS layout: could not add " + plugin + ": " + e);
        return null;
    }
    if (!widget) {
        print("FrostOS layout: widget not found: " + plugin);
        return null;
    }
    if (config) {
        for (var group in config) {
            widget.currentConfigGroup = group.split("/");
            var values = config[group];
            for (var key in values) {
                widget.writeConfig(key, values[key]);
            }
        }
    }
    return widget;
}

// ---------------------------------------------------------------- top bar ---
var topBar = new Panel;
topBar.location = "top";
topBar.height = 2 * Math.round(gridUnit * 1.6 / 2);
topBar.floating = false;
topBar.lengthMode = "fill";
topBar.opacity = "translucent";

addFrostWidget(topBar, "org.kde.plasma.kickoff", {
    "General": { "icon": "frostos-logo" }
});
addFrostWidget(topBar, "org.kde.plasma.appmenu");
addFrostWidget(topBar, "org.kde.plasma.panelspacer");
// Wi-Fi, Bluetooth, battery, volume and the notification center all live here.
addFrostWidget(topBar, "org.kde.plasma.systemtray");
addFrostWidget(topBar, "org.kde.plasma.digitalclock", {
    "Appearance": {
        "showDate": true,
        "dateDisplayFormat": 1,          // date beside the time, like "Wed 25 Nov 16:09"
        "dateFormat": "custom",
        "customDateFormat": "ddd d MMM"
    }
});

// ------------------------------------------------------------------- dock ---
var dock = new Panel;
dock.location = "bottom";
dock.height = 2 * Math.round(gridUnit * 3.2 / 2);
dock.floating = true;
dock.alignment = "center";
dock.lengthMode = "fit";           // only as wide as its icons
dock.opacity = "translucent";
dock.hiding = "none";

// Full-screen app grid ("Launchpad").
addFrostWidget(dock, "org.kde.plasma.kickerdash", {
    "General": { "icon": "frostos-launchpad" }
});
// Icons-only task manager: pinned apps + running apps with indicators.
addFrostWidget(dock, "org.kde.plasma.icontasks", {
    "General": {
        "launchers": [
            "applications:org.kde.dolphin.desktop",
            "applications:brave-browser.desktop",
            "applications:org.kde.konsole.desktop",
            "applications:org.kde.discover.desktop",
            "applications:systemsettings.desktop"
        ].join(","),
        "showOnlyCurrentDesktop": false
    }
});
addFrostWidget(dock, "org.kde.plasma.marginsseparator");
addFrostWidget(dock, "org.kde.plasma.trash");

// ---------------------------------------------------------------- desktop ---
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = "org.kde.image";
}

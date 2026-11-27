// FrostDE's notification service. Apps send notifications here; FrostDE shows
// them as banners (top right) and keeps them in the Notification Center.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // Every notification still in the Notification Center.
    readonly property var all: server.trackedNotifications.values
    // Notifications shown as banners right now.
    property var banners: []

    function hideBanner(n) {
        banners = banners.filter(b => b !== n);
    }

    function clearAll() {
        for (const n of all.slice())
            n.dismiss();
        banners = [];
    }

    function activate(n) {
        const action = n.actions.find(a => a.identifier === "default");
        if (action)
            action.invoke();
        n.dismiss();
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            if (!Config.doNotDisturb)
                root.banners = [n].concat(root.banners).slice(0, 4);
        }
    }
}

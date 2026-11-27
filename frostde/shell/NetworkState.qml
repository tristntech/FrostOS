// Network status from NetworkManager (asked every few seconds with nmcli).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property bool wifiConnected: false
    property string wifiName: ""
    property bool wiredConnected: false
    property bool hasWifiDevice: false

    function setWifi(on) {
        wifiEnabled = on;
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
        refreshSoon.restart();
    }

    function parse(text) {
        let wifiDev = false, wifiUp = false, wifiSsid = "", wiredUp = false, radio = false;
        for (const line of text.split("\n")) {
            if (line.startsWith("RADIO:")) {
                radio = line.substring(6).trim() === "enabled";
                continue;
            }
            // TYPE:STATE:CONNECTION  (":" inside names is escaped as "\:")
            const parts = line.replace(/\\:/g, "\u0001").split(":").map(p => p.replace(/\u0001/g, ":"));
            if (parts.length < 3)
                continue;
            const connected = parts[1] === "connected";
            if (parts[0] === "wifi") {
                wifiDev = true;
                if (connected) {
                    wifiUp = true;
                    wifiSsid = parts.slice(2).join(":");
                }
            } else if (parts[0] === "ethernet" && connected) {
                wiredUp = true;
            }
        }
        hasWifiDevice = wifiDev;
        wifiEnabled = radio;
        wifiConnected = wifiUp;
        wifiName = wifiSsid;
        wiredConnected = wiredUp;
    }

    Process {
        id: poll
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null; echo RADIO:$(nmcli radio wifi 2>/dev/null)"]
        stdout: StdioCollector {
            id: out
            onStreamFinished: root.parse(out.text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    Timer {
        id: refreshSoon
        interval: 1500
        onTriggered: poll.running = true
    }
}

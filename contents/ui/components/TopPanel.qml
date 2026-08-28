import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasma5support as P5Support

import "PopUpCards"

    // Top header panel: avatar, welcome text, battery, and action buttons.
    // Absorbs all its own data sources: fully self-contained.
    Rectangle {
        id: root
        property var theme
        property string userName: ""


        width: parent.width - 2
        height: 118
        radius: 10
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: theme.surface

        // Command source: settings, power
        P5Support.DataSource {
            id: commandSource
            engine: "executable"
            connectedSources: []
            onNewData: (sourceName, data) => disconnectSource(sourceName)
        }

        // ── WiFi data (lives here because PopUpCards/ can't access P5Support) ────────

        P5Support.DataSource {
            id: wifiSource
            engine: "executable"
            connectedSources: []

            onNewData: function(sourceName, data) {
                var out = (data["stdout"] || "").trim()

                if (sourceName.indexOf("nmcli -t -f active,ssid,signal dev wifi") === 0)
                    wifiNetworks = parseWifiNetworks(out)
                else if (sourceName.indexOf("nmcli radio wifi") === 0)
                    wifiEnabled = (out === "enabled")
                else if (sourceName.indexOf("nmcli -t -f device,type,state,connection dev") === 0)
                    ethernetConnections = parseEthernetDevices(out)

                disconnectSource(sourceName)
            }
        }

        property bool wifiEnabled: true
        property var  wifiNetworks: []
        property var ethernetConnections: []


        function wifiRefresh() {
            wifiSource.connectSource("nmcli radio wifi")
            wifiSource.connectSource("nmcli -t -f active,ssid,signal dev wifi list")
            wifiSource.connectSource("nmcli -t -f device,type,state,connection dev")
        }

        function toggleWifi(on) {
            wifiSource.connectSource("nmcli radio wifi " + (on ? "on" : "off"))
            wifiRefreshTimer.restart()
        }

        function connectToWifi(ssid) {
            wifiSource.connectSource("nmcli con up id '" + ssid + "'")
            wifiRefreshTimer.restart()
        }

        function parseWifiNetworks(raw) {
            var lines  = raw.split("\n")
            var result = []

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line === "") continue

                var parts = line.split(":")
                if (parts.length < 3) continue

                var active = parts[0] === "yes"
                var ssid   = parts[1]
                var signal = parseInt(parts[2]) || 0

                if (ssid === "") continue

                result.push({ ssid: ssid, signal: signal, active: active })
            }

            result.sort(function(a, b) {
                if (a.active !== b.active) return a.active ? -1 : 1
                return b.signal - a.signal
            })

            return result
        }

        function parseEthernetDevices(raw) {
            var lines  = raw.split("\n")
            var result = []

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line === "") continue

                // nmcli -t outputs:  enp3s0:ethernet:connected:Wired connection 1
                var parts = line.split(":")
                if (parts.length < 4) continue

                var device     = parts[0]
                var type       = parts[1]
                var state      = parts[2]
                var connection = parts[3]

                // Only ethernet, skip loopback
                if (type !== "ethernet") continue

                result.push({
                    device:     device,
                    connection: connection !== "" ? connection : device,
                    connected:  state === "connected"
                })
            }

            return result
        }

        // Delayed re-poll after toggle/connect actions
        Timer {
            id:          wifiRefreshTimer
            interval:    1200
            onTriggered: wifiRefresh()
        }

        // Avatar
        Item {
            id: pfpRect
            x: 8; y: 14
            width: 90; height: 90
            property string avatarSource: ""

            // Fetch identity once, then reuse it for the greeting and avatar lookup.
            P5Support.DataSource {
                id: accountsSource
                engine: "executable"
                connectedSources: []

                function exec(command) { connectSource(command) }

                onNewData: (sourceName, data) => {
                    if (data["exit code"] !== 0) { disconnectSource(sourceName); return }
                    var output = (data["stdout"] || "").trim()

                    if (sourceName === "whoami") {
                        root.userName = output
                        accountsSource.exec(
                            "test -f /var/lib/AccountsService/icons/" + output +
                            " && echo /var/lib/AccountsService/icons/" + output +
                            " || echo ~/.face"
                        )
                    } else {
                        if (output.length > 0)
                            pfpRect.avatarSource = "file://" + output
                    }
                    disconnectSource(sourceName)
                }

                Component.onCompleted: exec("whoami")
            }

            //pfp
            Image {
                id: avatarImg
                anchors.fill: parent
                source: pfpRect.avatarSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            Rectangle {
                id: circleMask
                anchors.fill: parent
                radius: width / 2
                visible: false
            }

            OpacityMask {
                anchors.fill: avatarImg
                source: avatarImg
                maskSource: circleMask
            }
        }

        // Right side: welcome text, battery, buttons
        Column {
            id: infoCol
            anchors.left: pfpRect.right
            anchors.leftMargin: 12
            anchors.verticalCenter: pfpRect.verticalCenter
            spacing: 4

            Text {
                text: "Hey, " + root.userName + "!"
                font.pointSize: 16
                color: theme.text
            }

            // Battery row, only visible if a battery is present
            Row {
                visible: batteryItem.hasBattery
                spacing: 4

                Item {
                    id: batteryItem
                    property int  percentage: 0
                    property bool charging:   false
                    property bool hasBattery: false

                    P5Support.DataSource {
                        id: pmSource
                        engine: "powermanagement"
                        connectedSources: ["Battery"]

                        onDataChanged: {
                            var battery = data["Battery"]
                            if (battery && battery["Has Battery"] !== undefined) {
                                batteryItem.hasBattery = battery["Has Battery"]
                                batteryItem.percentage = battery["Percent"] ?? 0
                                batteryItem.charging   = battery["State"] === "Charging"
                            }
                        }
                    }
                }

                Text  { text: batteryItem.percentage; color: theme.text; font.pointSize: 11 }
                ThemedIcon {
                    source: "../icons/battery-full.svg"
                    color: theme.batteryIconColor
                    width: 16
                    height: 16
                }
            }

            // Action buttons row
            Row {
                spacing: 7

                // Settings
                Item {
                    width: 22; height: 22
                    ThemedIcon {
                        anchors.fill: parent
                        source: "../icons/settings.svg"
                        color: theme.iconAction
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: commandSource.connectSource("systemsettings")
                    }
                }

                // WiFi popup is created only on first use.
                Item {
                    id:     wifiButton
                    width:  22
                    height: 22

                    ThemedIcon {
                        anchors.fill: parent
                        source:       "../icons/Wifi/wifi.svg"
                        color:        theme.wifiIconColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            if (!wifiPopupLoader.active) {
                                wifiPopupLoader.openAfterLoad = true
                                wifiPopupLoader.active = true
                            } else if (wifiPopupLoader.item) {
                                wifiPopupLoader.item.open()
                            }
                        }
                    }

                    // The popup is created only after the user requests it.
                    Loader {
                        id: wifiPopupLoader
                        property bool openAfterLoad: false
                        sourceComponent: Component {
                            WifiPopup {
                                x: -230
                                y: 15

                                wifiEnabled: root.wifiEnabled
                                networks: root.wifiNetworks
                                ethernetConnections: root.ethernetConnections
                                theme: root.theme

                                onRequestRefresh: root.wifiRefresh()
                                onToggleWifi: function(enable) {
                                    root.toggleWifi(enable)
                                }
                                onConnectToNetwork: function(ssid) {
                                    root.connectToWifi(ssid)
                                }
                                onOpenSettings: Qt.openUrlExternally("plasma-open-settings network")
                            }
                        }
                        onLoaded: {
                            if (openAfterLoad && item) {
                                openAfterLoad = false
                                item.open()
                            }
                        }
                    }
                }

                // Bluetooth, handler deferred to next session
                ThemedIcon {
                    source: "../icons/Bluetooth/bluetooth_static.svg"
                    width: 22; height: 22
                    color: theme.bluetoothIconColor
                }

                // KDE Connect, handler deferred to next session
                ThemedIcon {
                    source: "../icons/monitor-smartphone.svg"
                    width: 22; height: 22
                    color: theme.kdeConnectIconColor
                }
            }
        }

        // Power button
        Item {
            width: 28; height: 28
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8

            ThemedIcon {
                anchors.fill: parent
                source: "../icons/power.svg"
                color: theme.topPanelPowerIconColor
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: commandSource.connectSource(
                    "qdbus6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptAll"
                )
            }
        }
    }

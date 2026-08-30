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

        function closePopups(except) {
            if (except !== "wifi" && wifiPopupLoader.item)
                wifiPopupLoader.item.close()
            if (except !== "bluetooth" && bluetoothPopupLoader.item)
                bluetoothPopupLoader.item.close()
            if (except !== "kdeconnect" && kdeConnectPopupLoader.item)
                kdeConnectPopupLoader.item.close()
        }


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
                var out = String((data && data["stdout"]) || "").trim()
                var error = String((data && data["stderr"]) || "").trim()
                var exitCode = data && data["exit code"] !== undefined
                    ? parseInt(data["exit code"]) : 0
                var succeeded = isNaN(exitCode) || exitCode === 0

                if (sourceName === root.wifiRadioCommand) {
                    root.networkChecked = true
                    if (succeeded) {
                        root.networkManagerAvailable = true
                        root.wifiEnabled = out === "enabled"
                    } else {
                        root.networkManagerAvailable = false
                        root.wifiEnabled = false
                    }
                } else if (sourceName === root.wifiScanCommand) {
                    root.wifiScanning = false
                    root.networkChecked = true
                    if (succeeded) {
                        root.networkManagerAvailable = true
                        root.wifiNetworks = root.parseWifiNetworks(out)
                        root.wifiAvailable = root.wifiNetworks.length > 0
                            || root.wifiAvailable
                    } else {
                        root.wifiNetworks = []
                        root.wifiAvailable = false
                        root.networkManagerAvailable = error.indexOf("NetworkManager") === -1
                    }
                } else if (sourceName === root.deviceStatusCommand) {
                    root.networkChecked = true
                    if (succeeded) {
                        root.networkManagerAvailable = true
                        var devices = root.parseDevices(out)
                        root.wifiAvailable = devices.wifi
                        root.ethernetConnections = devices.ethernet
                    } else {
                        root.networkManagerAvailable = false
                        root.wifiAvailable = false
                        root.ethernetConnections = []
                    }
                } else if (sourceName.indexOf("nmcli radio wifi ") === 0) {
                    root.wifiBusy = false
                    root.wifiStatusMessage = succeeded
                        ? "Wi-Fi settings updated."
                        : (error || "Could not change Wi-Fi state.")
                    root.wifiStatusError = !succeeded
                    wifiRefreshTimer.restart()
                } else if (sourceName.indexOf("nmcli --wait 20 device wifi connect ") === 0) {
                    root.wifiBusy = false
                    root.wifiStatusMessage = succeeded
                        ? "Connected successfully."
                        : (error || "Could not connect to the network.")
                    root.wifiStatusError = !succeeded
                    wifiRefreshTimer.restart()
                }

                disconnectSource(sourceName)
            }
        }

        readonly property string wifiRadioCommand: "nmcli radio wifi"
        readonly property string wifiScanCommand: "nmcli -t --escape yes -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan yes"
        readonly property string deviceStatusCommand: "nmcli -t --escape yes -f DEVICE,TYPE,STATE,CONNECTION device status"

        property bool networkChecked: false
        property bool networkManagerAvailable: true
        property bool wifiAvailable: false
        property bool wifiEnabled: false
        property bool wifiScanning: false
        property bool wifiBusy: false
        property string wifiStatusMessage: ""
        property bool wifiStatusError: false
        property var wifiNetworks: []
        property var ethernetConnections: []

        function wifiRefresh(scan) {
            wifiSource.connectSource(root.wifiRadioCommand)
            wifiSource.connectSource(root.deviceStatusCommand)
            if (scan === true) {
                root.wifiStatusMessage = ""
                root.wifiStatusError = false
                root.wifiScanning = true
                wifiSource.connectSource(root.wifiScanCommand)
            }
        }

        function toggleWifi(on) {
            root.wifiBusy = true
            root.wifiStatusMessage = on ? "Turning Wi-Fi on..." : "Turning Wi-Fi off..."
            root.wifiStatusError = false
            wifiSource.connectSource("nmcli radio wifi " + (on ? "on" : "off"))
            wifiRefreshTimer.restart()
        }

        function connectToWifi(ssid, password) {
            if (ssid === "" || root.wifiBusy)
                return

            root.wifiBusy = true
            root.wifiStatusMessage = "Connecting to " + ssid + "..."
            root.wifiStatusError = false
            var command = "nmcli --wait 20 device wifi connect " + shellQuote(ssid)
            if (password !== "")
                command += " password " + shellQuote(password)
            wifiSource.connectSource(command)
        }

        function shellQuote(value) {
            return "'" + String(value).replace(/'/g, "'\"'\"'") + "'"
        }

        // nmcli --escape yes uses backslash escaping in terse output.
        function parseTerseLine(line) {
            var fields = []
            var field = ""
            var escaped = false
            for (var i = 0; i < line.length; i++) {
                var character = line.charAt(i)
                if (escaped) {
                    field += character
                    escaped = false
                } else if (character === "\\") {
                    escaped = true
                } else if (character === ":") {
                    fields.push(field)
                    field = ""
                } else {
                    field += character
                }
            }
            if (escaped)
                field += "\\"
            fields.push(field)
            return fields
        }

        function parseWifiNetworks(raw) {
            var lines  = raw.split("\n")
            var result = []
            var bySsid = ({})

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i]
                if (line === "") continue

                var parts = parseTerseLine(line)
                if (parts.length < 4) continue

                var active = parts[0] === "*" || parts[0] === "yes"
                var ssid   = parts[1]
                var signal = parseInt(parts[2]) || 0
                var security = parts[3]

                if (ssid === "") continue

                var network = {
                    ssid: ssid,
                    signal: signal,
                    security: security,
                    active: active,
                    requiresPassword: security !== "" && security !== "--"
                }
                if (bySsid[ssid] === undefined) {
                    bySsid[ssid] = network
                    result.push(network)
                } else if (signal > bySsid[ssid].signal) {
                    bySsid[ssid].signal = signal
                }
            }

            result.sort(function(a, b) {
                if (a.active !== b.active) return a.active ? -1 : 1
                return b.signal - a.signal
            })

            return result
        }

        function parseDevices(raw) {
            var lines = raw.split("\n")
            var hasWifi = false
            var ethernet = []

            for (var i = 0; i < lines.length; i++) {
                if (lines[i] === "") continue
                var parts = parseTerseLine(lines[i])
                if (parts.length < 4) continue

                var device = parts[0]
                var type = parts[1]
                var state = parts[2]
                var connection = parts[3]
                if (type === "wifi")
                    hasWifi = true
                else if (type === "ethernet")
                    ethernet.push({
                        device: device,
                        connection: connection !== "" ? connection : device,
                        connected: state === "connected"
                    })
            }
            return { wifi: hasWifi, ethernet: ethernet }
        }

        function parseEthernetDevices(raw) {
            var lines  = raw.split("\n")
            var result = []

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line === "") continue

                var parts = parseTerseLine(line)
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

        // Bluetooth data and actions. bluetoothctl can wait indefinitely when
        // BlueZ is unavailable, so every command has an explicit timeout.
        P5Support.DataSource {
            id: bluetoothSource
            engine: "executable"
            connectedSources: []

            onNewData: function(sourceName, data) {
                var out = String((data && data["stdout"]) || "").trim()
                var error = String((data && data["stderr"]) || "").trim()
                var exitCode = data && data["exit code"] !== undefined
                    ? parseInt(data["exit code"]) : 0
                var succeeded = isNaN(exitCode) || exitCode === 0

                if (sourceName === root.bluetoothShowCommand) {
                    root.bluetoothChecked = true
                    root.bluetoothControllerAvailable = succeeded &&
                        out.indexOf("Controller") !== -1
                    if (root.bluetoothControllerAvailable) {
                        var powered = out.match(/^Powered:\s+(yes|no)$/m)
                        root.bluetoothPowered = powered && powered[1] === "yes"
                    } else {
                        root.bluetoothPowered = false
                        root.bluetoothDevices = []
                    }
                } else if (sourceName === root.bluetoothDevicesCommand) {
                    if (succeeded) {
                        root.bluetoothControllerAvailable = true
                        root.bluetoothDevices = root.parseBluetoothDevices(out)
                        for (var i = 0; i < root.bluetoothDevices.length; i++)
                            bluetoothSource.connectSource(
                                root.bluetoothInfoPrefix +
                                root.shellQuote(root.bluetoothDevices[i].address)
                            )
                    } else if (!root.bluetoothControllerAvailable) {
                        root.bluetoothDevices = []
                    }
                } else if (sourceName.indexOf(root.bluetoothInfoPrefix) === 0) {
                    if (succeeded)
                        root.updateBluetoothDevice(root.parseBluetoothInfo(out))
                } else if (sourceName === root.bluetoothScanCommand) {
                    root.bluetoothScanning = false
                    root.bluetoothBusy = false
                    root.bluetoothStatusMessage = succeeded
                        ? "Scan complete."
                        : (error || "Could not scan for Bluetooth devices.")
                    root.bluetoothStatusError = !succeeded
                    bluetoothRefreshTimer.restart()
                } else if (sourceName.indexOf(root.bluetoothPowerPrefix) === 0 ||
                           sourceName.indexOf(root.bluetoothConnectPrefix) === 0 ||
                           sourceName.indexOf(root.bluetoothDisconnectPrefix) === 0 ||
                           sourceName.indexOf(root.bluetoothPairPrefix) === 0) {
                    root.bluetoothBusy = false
                    root.bluetoothStatusMessage = succeeded
                        ? root.bluetoothActionSuccessMessage
                        : (error || "Bluetooth action failed.")
                    root.bluetoothStatusError = !succeeded
                    bluetoothRefreshTimer.restart()
                }

                disconnectSource(sourceName)
            }
        }

        readonly property string bluetoothShowCommand: "timeout 6s bluetoothctl --timeout 5 show"
        readonly property string bluetoothDevicesCommand: "timeout 6s bluetoothctl --timeout 5 devices"
        readonly property string bluetoothScanCommand: "timeout 12s bluetoothctl --timeout 10 scan on"
        readonly property string bluetoothInfoPrefix: "timeout 6s bluetoothctl --timeout 5 info "
        readonly property string bluetoothPowerPrefix: "timeout 8s bluetoothctl --timeout 7 power "
        readonly property string bluetoothConnectPrefix: "timeout 14s bluetoothctl --timeout 12 connect "
        readonly property string bluetoothDisconnectPrefix: "timeout 10s bluetoothctl --timeout 8 disconnect "
        readonly property string bluetoothPairPrefix: "timeout 22s bluetoothctl --timeout 20 --agent KeyboardDisplay --default-agent pair "

        property bool bluetoothControllerAvailable: false
        property bool bluetoothPowered: false
        property bool bluetoothChecked: false
        property bool bluetoothScanning: false
        property bool bluetoothBusy: false
        property string bluetoothStatusMessage: ""
        property bool bluetoothStatusError: false
        property string bluetoothActionSuccessMessage: ""
        property var bluetoothDevices: []

        function parseBluetoothDevices(raw) {
            var result = []
            var lines = raw.split("\n")

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                var match = line.match(/^Device\s+([0-9A-Fa-f:]{17})(?:\s+(.*))?$/)
                if (!match)
                    continue

                result.push({
                    address: match[1],
                    name: (match[2] || "").trim(),
                    connected: false,
                    paired: false,
                    trusted: false
                })
            }

            result.sort(function(a, b) {
                return a.name.localeCompare(b.name)
            })
            return result
        }

        function bluetoothInfoField(raw, field) {
            var match = raw.match(new RegExp("^" + field + ":\\s*(.*)$", "m"))
            return match ? match[1].trim() : ""
        }

        function parseBluetoothInfo(raw) {
            var addressMatch = raw.match(/^Device\s+([0-9A-Fa-f:]{17})/m)
            var address = addressMatch ? addressMatch[1] : ""
            var name = bluetoothInfoField(raw, "Name")
            var alias = bluetoothInfoField(raw, "Alias")

            return {
                address: address,
                name: name !== "" ? name : alias,
                connected: bluetoothInfoField(raw, "Connected") === "yes",
                paired: bluetoothInfoField(raw, "Paired") === "yes",
                trusted: bluetoothInfoField(raw, "Trusted") === "yes"
            }
        }

        function updateBluetoothDevice(info) {
            if (!info || info.address === "")
                return

            var updated = bluetoothDevices.slice()
            for (var i = 0; i < updated.length; i++) {
                if (updated[i].address !== info.address)
                    continue

                var current = updated[i]
                updated[i] = {
                    address: current.address,
                    name: info.name !== "" ? info.name : current.name,
                    connected: info.connected,
                    paired: info.paired,
                    trusted: info.trusted
                }
                break
            }

            updated.sort(function(a, b) {
                if (a.connected !== b.connected)
                    return a.connected ? -1 : 1
                if (a.paired !== b.paired)
                    return a.paired ? -1 : 1
                return a.name.localeCompare(b.name)
            })
            root.bluetoothDevices = updated
        }

        function refreshBluetooth() {
            bluetoothSource.connectSource(root.bluetoothShowCommand)
            bluetoothSource.connectSource(root.bluetoothDevicesCommand)
        }

        function toggleBluetooth(on) {
            root.bluetoothBusy = true
            root.bluetoothActionSuccessMessage = on ? "Bluetooth enabled." :
                "Bluetooth disabled."
            root.bluetoothStatusMessage = on ? "Turning Bluetooth on..." :
                "Turning Bluetooth off..."
            root.bluetoothStatusError = false
            bluetoothSource.connectSource(root.bluetoothPowerPrefix + (on ? "on" : "off"))
        }

        function scanBluetooth() {
            if (root.bluetoothBusy)
                return
            root.bluetoothBusy = true
            root.bluetoothScanning = true
            root.bluetoothStatusMessage = "Scanning for Bluetooth devices..."
            root.bluetoothStatusError = false
            bluetoothSource.connectSource(root.bluetoothScanCommand)
        }

        function connectBluetooth(address) {
            if (root.bluetoothBusy)
                return
            root.bluetoothBusy = true
            root.bluetoothActionSuccessMessage = "Device connected."
            root.bluetoothStatusMessage = "Connecting to device..."
            root.bluetoothStatusError = false
            bluetoothSource.connectSource(
                root.bluetoothConnectPrefix + root.shellQuote(address)
            )
        }

        function disconnectBluetooth(address) {
            if (root.bluetoothBusy)
                return
            root.bluetoothBusy = true
            root.bluetoothActionSuccessMessage = "Device disconnected."
            root.bluetoothStatusMessage = "Disconnecting device..."
            root.bluetoothStatusError = false
            bluetoothSource.connectSource(
                root.bluetoothDisconnectPrefix + root.shellQuote(address)
            )
        }

        function pairBluetooth(address) {
            if (root.bluetoothBusy)
                return
            root.bluetoothBusy = true
            root.bluetoothActionSuccessMessage = "Pairing request sent."
            root.bluetoothStatusMessage = "Pairing device..."
            root.bluetoothStatusError = false
            bluetoothSource.connectSource(
                root.bluetoothPairPrefix + root.shellQuote(address)
            )
        }

        Timer {
            id: bluetoothRefreshTimer
            interval: 1400
            onTriggered: root.refreshBluetooth()
        }

        // KDE Connect discovery and remote-device actions.
        P5Support.DataSource {
            id: kdeConnectSource
            engine: "executable"
            connectedSources: []

            onNewData: function(sourceName, data) {
                var out = String((data && data["stdout"]) || "").trim()
                var error = String((data && data["stderr"]) || "").trim()
                var exitCode = data && data["exit code"] !== undefined
                    ? parseInt(data["exit code"]) : 0
                var succeeded = isNaN(exitCode) || exitCode === 0

                if (sourceName === root.kdeDevicesCommand) {
                    root.kdeChecked = true
                    if (succeeded) {
                        root.kdeServiceAvailable = true
                        root.kdePairedDevices = root.parseKdeDevices(out)
                        root.updateKdeDevices()
                        root.queryKdeDeviceInfo()
                    } else if (!root.kdeServiceAvailable) {
                        root.kdeDevices = []
                    }
                } else if (sourceName === root.kdeAvailableCommand) {
                    root.kdeChecked = true
                    if (succeeded) {
                        root.kdeServiceAvailable = true
                        var available = root.parseKdeDevices(out)
                        var availableIds = ({})
                        for (var i = 0; i < available.length; i++)
                            availableIds[available[i].id] = available[i].name
                        root.kdeAvailableIds = availableIds
                        root.updateKdeDevices()
                        root.queryKdeDeviceInfo()
                    } else if (!root.kdeServiceAvailable) {
                        root.kdeDevices = []
                    }
                } else if (root.kdeInfoCommands[sourceName] !== undefined) {
                    if (succeeded)
                        root.updateKdeDeviceInfo(sourceName, out)
                } else if (sourceName === root.kdeRefreshCommand) {
                    root.kdeBusy = false
                    root.kdeStatusMessage = succeeded
                        ? "Device discovery refreshed."
                        : (error || "Could not refresh KDE Connect.")
                    root.kdeStatusError = !succeeded
                    kdeConnectRefreshTimer.restart()
                } else if (sourceName.indexOf(root.kdeActionPrefix) === 0 ||
                           sourceName.indexOf(root.kdeDbusActionPrefix) === 0) {
                    if (sourceName.indexOf(" --list-notifications") !== -1) {
                        root.kdeBusy = false
                        root.kdeNotificationsChecked = true
                        root.kdeNotifications = succeeded
                            ? root.parseKdeNotifications(out) : []
                        root.kdeStatusMessage = succeeded
                            ? "" : (error || "Could not load phone notifications.")
                        root.kdeStatusError = !succeeded
                    } else if (sourceName.indexOf(" --share ") !== -1 &&
                            root.kdeSharePending > 0) {
                        root.kdeShareFailed = root.kdeShareFailed || !succeeded
                        if (!succeeded && root.kdeShareErrorMessage === "")
                            root.kdeShareErrorMessage = error ||
                                "Could not share the selected file."
                        root.kdeSharePending--
                        if (root.kdeSharePending === 0) {
                            root.kdeBusy = false
                            root.kdeStatusMessage = root.kdeShareFailed
                                ? root.kdeShareErrorMessage
                                : root.kdeActionSuccessMessage
                            root.kdeStatusError = root.kdeShareFailed
                            kdeConnectRefreshTimer.restart()
                        }
                    } else {
                        root.kdeBusy = false
                        root.kdeStatusMessage = succeeded
                            ? root.kdeActionSuccessMessage
                            : (error || "KDE Connect action failed.")
                        root.kdeStatusError = !succeeded
                        kdeConnectRefreshTimer.restart()
                    }
                }

                disconnectSource(sourceName)
            }
        }

        readonly property string kdeDevicesCommand: "timeout 8s kdeconnect-cli --list-devices --id-name-only"
        readonly property string kdeAvailableCommand: "timeout 8s kdeconnect-cli --list-available --id-name-only"
        readonly property string kdeRefreshCommand: "timeout 14s kdeconnect-cli --refresh"
        readonly property string kdeActionPrefix: "timeout 14s kdeconnect-cli --device "
        readonly property string kdeDbusActionPrefix: "timeout 12s qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/"
        readonly property string kdeBatteryCommandPrefix: "timeout 8s qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/"
        readonly property string kdeProviderCommandPrefix: "timeout 8s qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/"

        property bool kdeServiceAvailable: false
        property bool kdeChecked: false
        property bool kdeBusy: false
        property string kdeStatusMessage: ""
        property bool kdeStatusError: false
        property string kdeActionSuccessMessage: ""
        property int kdeSharePending: 0
        property bool kdeShareFailed: false
        property string kdeShareErrorMessage: ""
        property var kdePairedDevices: []
        property var kdeAvailableIds: ({})
        property var kdeInfoCommands: ({})
        property var kdeDevices: []
        property var kdeNotifications: []
        property bool kdeNotificationsChecked: false

        function parseKdeNotifications(raw) {
            var result = []
            var lines = String(raw || "").split("\n")

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.indexOf("- ") !== 0)
                    continue

                var content = line.substring(2)
                var separator = content.indexOf(":")
                if (separator === -1) {
                    result.push({ appName: "Phone", text: content })
                    continue
                }

                result.push({
                    appName: content.substring(0, separator).trim() || "Phone",
                    text: content.substring(separator + 1).trim()
                })
            }
            return result
        }

        function parseKdeDevices(raw) {
            var result = []
            var lines = raw.split("\n")

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                var match = line.match(/^([0-9A-Fa-f]{16,})(?:\s+(.*))?$/)
                if (!match)
                    continue

                result.push({
                    id: match[1],
                    name: (match[2] || "").trim(),
                    batteryCharge: -1,
                    networkLabel: ""
                })
            }
            return result
        }

        function updateKdeDevices() {
            var merged = []
            var indexById = ({})

            for (var i = 0; i < root.kdePairedDevices.length; i++) {
                var paired = root.kdePairedDevices[i]
                merged.push({
                    id: paired.id,
                    name: paired.name,
                    available: root.kdeAvailableIds[paired.id] !== undefined,
                    batteryCharge: paired.batteryCharge,
                    networkLabel: paired.networkLabel
                })
                indexById[paired.id] = merged.length - 1
            }

            for (var id in root.kdeAvailableIds) {
                if (indexById[id] !== undefined)
                    continue
                merged.push({
                    id: id,
                    name: root.kdeAvailableIds[id],
                    available: true,
                    batteryCharge: -1,
                    networkLabel: ""
                })
            }

            merged.sort(function(a, b) {
                if (a.available !== b.available)
                    return a.available ? -1 : 1
                return a.name.localeCompare(b.name)
            })
            root.kdeDevices = merged
        }

        function queryKdeDeviceInfo() {
            var commands = ({})
            for (var i = 0; i < root.kdeDevices.length; i++) {
                var id = root.kdeDevices[i].id
                if (!/^[0-9a-fA-F]{16,}$/.test(id))
                    continue

                var batteryCommand = root.kdeBatteryCommandPrefix +
                    root.shellQuote(id) +
                    "/battery org.kde.kdeconnect.device.battery.charge"
                var providerCommand = root.kdeProviderCommandPrefix +
                    root.shellQuote(id) +
                    " org.kde.kdeconnect.device.activeProviderNames"

                commands[batteryCommand] = { id: id, type: "battery" }
                commands[providerCommand] = { id: id, type: "provider" }
            }

            root.kdeInfoCommands = commands
            for (var command in commands)
                kdeConnectSource.connectSource(command)
        }

        function updateKdeDeviceInfo(sourceName, output) {
            var query = root.kdeInfoCommands[sourceName]
            if (!query)
                return

            var updated = root.kdeDevices.slice()
            for (var i = 0; i < updated.length; i++) {
                if (updated[i].id !== query.id)
                    continue

                var current = updated[i]
                updated[i] = {
                    id: current.id,
                    name: current.name,
                    available: current.available,
                    batteryCharge: query.type === "battery"
                        ? parseInt(output) : current.batteryCharge,
                    networkLabel: query.type === "provider"
                        ? output.replace(/\s+/g, " ").trim() : current.networkLabel
                }
                break
            }
            root.kdeDevices = updated
        }

        function refreshKdeConnect() {
            kdeConnectSource.connectSource(root.kdeDevicesCommand)
            kdeConnectSource.connectSource(root.kdeAvailableCommand)
        }

        function refreshKdeDiscovery() {
            if (root.kdeBusy)
                return
            root.kdeBusy = true
            root.kdeStatusMessage = "Refreshing device discovery..."
            root.kdeStatusError = false
            kdeConnectSource.connectSource(root.kdeRefreshCommand)
        }

        function runKdeAction(deviceId, action, successMessage) {
            var allowedActions = ["ring", "browse", "notifications", "clipboard", "unpair"]
            if (root.kdeBusy || allowedActions.indexOf(action) === -1)
                return

            root.kdeBusy = true
            root.kdeActionSuccessMessage = successMessage + "."
            root.kdeStatusMessage = successMessage + "..."
            root.kdeStatusError = false

            var command
            if (action === "browse") {
                command = root.kdeDbusActionPrefix + root.shellQuote(deviceId) +
                    "/sftp org.kde.kdeconnect.device.sftp.startBrowsing"
            } else if (action === "clipboard") {
                command = root.kdeDbusActionPrefix + root.shellQuote(deviceId) +
                    "/clipboard org.kde.kdeconnect.device.clipboard.sendClipboard"
            } else if (action === "ring") {
                command = root.kdeActionPrefix + root.shellQuote(deviceId) + " --ring"
            } else if (action === "notifications") {
                root.kdeNotifications = []
                root.kdeNotificationsChecked = false
                command = root.kdeActionPrefix + root.shellQuote(deviceId) +
                    " --list-notifications"
            } else {
                command = root.kdeActionPrefix + root.shellQuote(deviceId) + " --unpair"
            }
            kdeConnectSource.connectSource(command)
        }

        function shareKdeFiles(deviceId, urls) {
            if (root.kdeBusy || !urls || urls.length === 0)
                return

            root.kdeSharePending = urls.length
            root.kdeShareFailed = false
            root.kdeShareErrorMessage = ""
            root.kdeBusy = true
            root.kdeActionSuccessMessage = urls.length === 1
                ? "File shared." : "Files shared."
            root.kdeStatusMessage = urls.length === 1
                ? "Sharing file..." : "Sharing files..."
            root.kdeStatusError = false

            for (var i = 0; i < urls.length; i++) {
                var url = String(urls[i])
                kdeConnectSource.connectSource(
                    root.kdeActionPrefix + root.shellQuote(deviceId) +
                    " --share " + root.shellQuote(url)
                )
            }
        }

        Timer {
            id: kdeConnectRefreshTimer
            interval: 1400
            onTriggered: root.refreshKdeConnect()
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
                id: batteryRow
                visible: hasBattery
                height: 18
                spacing: 4

                property int  percentage: 0
                property bool charging:   false
                property bool hasBattery: false

                function iconSource() {
                    if (charging)
                        return "../icons/Battery/battery-charging.svg"
                    if (percentage <= 15)
                        return "../icons/Battery/battery-empty.svg"
                    if (percentage <= 40)
                        return "../icons/Battery/battery-low.svg"
                    if (percentage <= 75)
                        return "../icons/Battery/battery-medium.svg"
                    return "../icons/battery-full.svg"
                }

                P5Support.DataSource {
                    id: pmSource
                    engine: "powermanagement"
                    connectedSources: ["Battery"]

                    onDataChanged: {
                        var battery = data["Battery"]
                        if (battery && battery["Has Battery"] !== undefined) {
                            batteryRow.hasBattery = battery["Has Battery"]
                            batteryRow.percentage = Math.max(0, Math.min(100,
                                Math.round(battery["Percent"] ?? 0)))
                            batteryRow.charging = battery["State"] === "Charging"
                        }
                    }
                }

                Text {
                    width: 40
                    height: parent.height
                    text: batteryRow.percentage + "%"
                    color: theme.text
                    font.pointSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                ThemedIcon {
                    source: batteryRow.iconSource()
                    color: theme.batteryIconColor
                    width: 18
                    height: 18
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
                            root.closePopups("wifi")
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
                                parent: root
                                x: Math.max(4, root.width - width - 8)
                                y: root.height - 4

                                wifiEnabled: root.wifiEnabled
                                networkChecked: root.networkChecked
                                networkManagerAvailable: root.networkManagerAvailable
                                wifiAvailable: root.wifiAvailable
                                wifiScanning: root.wifiScanning
                                wifiBusy: root.wifiBusy
                                wifiStatusMessage: root.wifiStatusMessage
                                wifiStatusError: root.wifiStatusError
                                networks: root.wifiNetworks
                                ethernetConnections: root.ethernetConnections
                                theme: root.theme

                                onRequestRefresh: root.wifiRefresh(true)
                                onToggleWifi: function(enable) {
                                    root.toggleWifi(enable)
                                }
                                onConnectToNetwork: function(ssid, password) {
                                    root.connectToWifi(ssid, password)
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

                // Bluetooth popup is created only on first use.
                Item {
                    id: bluetoothButton
                    width: 22
                    height: 22

                    ThemedIcon {
                        anchors.fill: parent
                        source: "../icons/Bluetooth/bluetooth_static.svg"
                        color: root.bluetoothControllerAvailable && root.bluetoothPowered
                            ? theme.bluetoothIconColor : theme.subtext
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.closePopups("bluetooth")
                            if (!bluetoothPopupLoader.active) {
                                bluetoothPopupLoader.openAfterLoad = true
                                bluetoothPopupLoader.active = true
                            } else if (bluetoothPopupLoader.item) {
                                bluetoothPopupLoader.item.open()
                            }
                        }
                    }

                    Loader {
                        id: bluetoothPopupLoader
                        property bool openAfterLoad: false
                        sourceComponent: Component {
                            BluetoothPopup {
                                parent: root
                                x: Math.max(4, root.width - width - 8)
                                y: root.height - 4

                                controllerAvailable: root.bluetoothControllerAvailable
                                bluetoothPowered: root.bluetoothPowered
                                bluetoothChecked: root.bluetoothChecked
                                bluetoothScanning: root.bluetoothScanning
                                bluetoothBusy: root.bluetoothBusy
                                statusMessage: root.bluetoothStatusMessage
                                statusError: root.bluetoothStatusError
                                devices: root.bluetoothDevices
                                theme: root.theme

                                onRequestRefresh: root.refreshBluetooth()
                                onToggleBluetooth: function(enable) {
                                    root.toggleBluetooth(enable)
                                }
                                onScanRequested: root.scanBluetooth()
                                onConnectDevice: function(address) {
                                    root.connectBluetooth(address)
                                }
                                onDisconnectDevice: function(address) {
                                    root.disconnectBluetooth(address)
                                }
                                onPairDevice: function(address) {
                                    root.pairBluetooth(address)
                                }
                                onOpenSettings: commandSource.connectSource(
                                    "kcmshell6 kcm_bluetooth"
                                )
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

                // KDE Connect popup is created only on first use.
                Item {
                    id: kdeConnectButton
                    width: 22
                    height: 22

                    ThemedIcon {
                        anchors.fill: parent
                        source: "../icons/monitor-smartphone.svg"
                        color: root.kdeServiceAvailable && root.kdeDevices.length > 0
                            ? theme.kdeConnectIconColor : theme.subtext
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.closePopups("kdeconnect")
                            if (!kdeConnectPopupLoader.active) {
                                kdeConnectPopupLoader.openAfterLoad = true
                                kdeConnectPopupLoader.active = true
                            } else if (kdeConnectPopupLoader.item) {
                                kdeConnectPopupLoader.item.open()
                            }
                        }
                    }

                    Loader {
                        id: kdeConnectPopupLoader
                        property bool openAfterLoad: false
                        sourceComponent: Component {
                            KdeConnectPopup {
                                parent: root
                                x: Math.max(4, root.width - width - 8)
                                y: root.height - 4

                                serviceAvailable: root.kdeServiceAvailable
                                checked: root.kdeChecked
                                busy: root.kdeBusy
                                statusMessage: root.kdeStatusMessage
                                statusError: root.kdeStatusError
                                devices: root.kdeDevices
                                notifications: root.kdeNotifications
                                notificationsChecked: root.kdeNotificationsChecked
                                theme: root.theme

                                onRequestRefresh: root.refreshKdeConnect()
                                onRefreshRequested: root.refreshKdeDiscovery()
                                onShareRequested: function(deviceId, urls) {
                                    root.shareKdeFiles(deviceId, urls)
                                }
                                onDeviceAction: function(deviceId, action, successMessage) {
                                    root.runKdeAction(deviceId, action, successMessage)
                                }
                                onOpenSettings: commandSource.connectSource("kdeconnect-app")
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

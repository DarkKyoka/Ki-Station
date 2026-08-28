import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmaComponents3.Popup {
    id: root

    width:  260
    height: 320

    background: Rectangle{
        color: theme.surfaceAlt
        radius:       10
        border.color: theme.border
        border.width: 1
    }

    closePolicy: PlasmaComponents3.Popup.CloseOnEscape |
        PlasmaComponents3.Popup.CloseOnPressOutside

    // ── Properties (data flows in from TopPanel) ─────────────────────────────

    property bool wifiEnabled: true
    property var  networks:    []   // [ { ssid, signal, active } ]
    property var  ethernetConnections: []
    property var  theme

    // ── Signals (actions bubble up to TopPanel) ──────────────────────────────

    signal toggleWifi(bool enable)
    signal connectToNetwork(string ssid)
    signal openSettings()
    signal requestRefresh()

    onOpened: root.requestRefresh()

    // UI

    ColumnLayout {
        anchors.fill:    parent
        anchors.margins: 12
        spacing:         8

        // Header row: label + toggle
        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents3.Label {
                text:      "Wi-Fi"
                font.bold: true
                color: theme.text
                Layout.fillWidth: true
            }

            PlasmaComponents3.Switch {
                checked: root.wifiEnabled
                onToggled: root.toggleWifi(checked)
            }
        }

        PlasmaComponents3.MenuSeparator { Layout.fillWidth: true }

        // Ethernet section
        // Only shown when at least one ethernet device exists
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.ethernetConnections.length > 0

            PlasmaComponents3.Label {
                text:           "Wired"
                font.bold:      true
                font.pointSize: 8
                color:          theme.subtext
            }

            // Repeater is fine here — rarely more than 1-2 ethernet devices
            Repeater {
                model: root.ethernetConnections

                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Connected indicator dot
                    Rectangle {
                        width:  8
                        height: 8
                        radius: 4
                        color:  modelData.connected
                            ? theme.positive
                            : theme.subtext
                    }

                    // Connection name
                    PlasmaComponents3.Label {
                        text:             modelData.connection
                        elide:            Text.ElideRight
                        Layout.fillWidth: true
                        font.bold:        modelData.connected
                        color:            theme.text
                    }

                    // Device name (e.g. enp3s0)
                    PlasmaComponents3.Label {
                        text:           modelData.device
                        opacity:        0.5
                        font.pointSize: 8
                        color:          theme.subtext
                    }
                }
            }
        }

        // Network list
        PlasmaComponents3.ScrollView {
            Layout.fillWidth:  true
            Layout.fillHeight: true

            ListView {
                id:      networkList
                model:   root.networks
                spacing: 2

                delegate: Controls.ItemDelegate {
                    width:       networkList.width
                    highlighted: modelData.active

                    contentItem: RowLayout {
                        spacing: 8

                        // Active checkmark
                        PlasmaComponents3.Label {
                            text:      modelData.active ? "✓" : " "
                            color:     modelData.active
                                ? theme.positive
                                : "transparent"
                            font.bold: true
                        }

                        // SSID
                        PlasmaComponents3.Label {
                            text:             modelData.ssid
                            elide:            Text.ElideRight
                            Layout.fillWidth: true
                        font.bold:        modelData.active
                        color:            theme.text
                        }

                        // Signal strength
                        PlasmaComponents3.Label {
                            text:           modelData.signal + "%"
                        opacity:        0.6
                        font.pointSize: 8
                        color:          theme.subtext
                        }
                    }

                    onClicked: {
                        if (!modelData.active)
                            root.connectToNetwork(modelData.ssid)
                    }
                }
            }
        }

        PlasmaComponents3.MenuSeparator { Layout.fillWidth: true }

        PlasmaComponents3.Button {
            Layout.fillWidth: true
            text:             "Network Settings…"
            icon.name:        "preferences-system-network"
            onClicked: {
                root.close()
                root.openSettings()
            }
        }
    }
}

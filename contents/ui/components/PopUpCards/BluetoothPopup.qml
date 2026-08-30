import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.components as PlasmaComponents3

PlasmaComponents3.Popup {
    id: root

    width: 320
    height: 430

    property bool controllerAvailable: false
    property bool bluetoothPowered: false
    property bool bluetoothChecked: false
    property bool bluetoothScanning: false
    property bool bluetoothBusy: false
    property string statusMessage: ""
    property bool statusError: false
    property var devices: []
    property var theme

    signal toggleBluetooth(bool enable)
    signal scanRequested()
    signal connectDevice(string address)
    signal disconnectDevice(string address)
    signal pairDevice(string address)
    signal openSettings()
    signal requestRefresh()

    closePolicy: PlasmaComponents3.Popup.CloseOnEscape |
        PlasmaComponents3.Popup.CloseOnPressOutside

    onOpened: root.requestRefresh()

    background: Rectangle {
        color: root.theme.surfaceAlt
        radius: 8
        border.color: root.theme.border
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents3.Label {
                text: "Bluetooth"
                color: root.theme.text
                font.bold: true
                Layout.fillWidth: true
            }

            PlasmaComponents3.Label {
                text: !root.bluetoothChecked ? "Checking..." :
                    (!root.controllerAvailable ? "Unavailable" :
                    (root.bluetoothPowered ? "On" : "Off"))
                color: !root.controllerAvailable ? root.theme.subtext :
                    (root.bluetoothPowered ? root.theme.positive : root.theme.subtext)
                font.pointSize: 8
            }

            PlasmaComponents3.Switch {
                checked: root.bluetoothPowered
                enabled: root.controllerAvailable && !root.bluetoothBusy
                onToggled: root.toggleBluetooth(checked)
            }

            PlasmaComponents3.Button {
                icon.name: "view-refresh"
                display: PlasmaComponents3.Button.IconOnly
                enabled: root.controllerAvailable && !root.bluetoothBusy
                onClicked: root.scanRequested()
                Controls.ToolTip.text: "Scan for Bluetooth devices"
                Controls.ToolTip.visible: hovered
            }
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: root.statusMessage !== ""
            text: root.statusMessage
            color: root.statusError ? root.theme.negative : root.theme.subtext
            font.pointSize: 8
            wrapMode: Text.Wrap
        }

        PlasmaComponents3.MenuSeparator { Layout.fillWidth: true }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: root.bluetoothScanning ||
                (root.bluetoothChecked && !root.controllerAvailable) ||
                (root.bluetoothChecked && root.controllerAvailable && root.devices.length === 0)
            text: root.bluetoothScanning ? "Scanning for devices..." :
                (!root.controllerAvailable ? "No Bluetooth adapter or service detected." :
                (root.bluetoothPowered ? "No paired or nearby devices." : "Bluetooth is turned off."))
            color: root.theme.subtext
            font.pointSize: 8
            wrapMode: Text.Wrap
        }

        Controls.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: deviceList
                model: root.devices
                spacing: 2
                interactive: contentHeight > height

                delegate: Controls.ItemDelegate {
                    width: deviceList.width
                    height: 58
                    enabled: root.controllerAvailable && root.bluetoothPowered && !root.bluetoothBusy

                    background: Rectangle {
                        radius: 4
                        color: parent.hovered ? Qt.alpha(root.theme.text, 0.08) : "transparent"
                    }

                    contentItem: RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: modelData.connected ? root.theme.positive :
                                (modelData.paired ? root.theme.accent : root.theme.subtext)
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 8
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true

                            PlasmaComponents3.Label {
                                text: modelData.name !== "" ? modelData.name : modelData.address
                                color: root.theme.text
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            PlasmaComponents3.Label {
                                text: modelData.connected ? "Connected" :
                                    (modelData.paired ? "Paired" : "Nearby")
                                color: modelData.connected ? root.theme.positive : root.theme.subtext
                                font.pointSize: 8
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        PlasmaComponents3.Button {
                            visible: !modelData.paired
                            icon.name: "list-add"
                            display: PlasmaComponents3.Button.IconOnly
                            onClicked: root.pairDevice(modelData.address)
                            Controls.ToolTip.text: "Pair device"
                            Controls.ToolTip.visible: hovered
                        }

                        PlasmaComponents3.Button {
                            visible: modelData.paired && !modelData.connected
                            icon.name: "network-connect"
                            display: PlasmaComponents3.Button.IconOnly
                            onClicked: root.connectDevice(modelData.address)
                            Controls.ToolTip.text: "Connect device"
                            Controls.ToolTip.visible: hovered
                        }

                        PlasmaComponents3.Button {
                            visible: modelData.connected
                            icon.name: "network-disconnect"
                            display: PlasmaComponents3.Button.IconOnly
                            onClicked: root.disconnectDevice(modelData.address)
                            Controls.ToolTip.text: "Disconnect device"
                            Controls.ToolTip.visible: hovered
                        }
                    }

                    onClicked: {
                        if (modelData.connected)
                            root.disconnectDevice(modelData.address)
                        else if (modelData.paired)
                            root.connectDevice(modelData.address)
                        else
                            root.pairDevice(modelData.address)
                    }
                }
            }
        }

        PlasmaComponents3.MenuSeparator { Layout.fillWidth: true }

        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents3.Button {
                text: "Scan"
                icon.name: "view-refresh"
                enabled: root.controllerAvailable && !root.bluetoothBusy
                Layout.fillWidth: true
                onClicked: root.scanRequested()
            }

            PlasmaComponents3.Button {
                text: "Bluetooth Settings"
                icon.name: "configure"
                enabled: !root.bluetoothBusy
                Layout.fillWidth: true
                onClicked: {
                    root.close()
                    root.openSettings()
                }
            }
        }
    }
}

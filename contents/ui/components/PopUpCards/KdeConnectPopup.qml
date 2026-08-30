import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs
import QtQuick.Controls as Controls
import org.kde.plasma.components as PlasmaComponents3

PlasmaComponents3.Popup {
    id: root

    width: 380
    height: 420

    property bool serviceAvailable: false
    property bool checked: false
    property bool busy: false
    property string statusMessage: ""
    property bool statusError: false
    property var devices: []
    property var theme
    property string selectedDeviceId: ""

    readonly property var activeDevice: {
        if (root.devices.length === 0)
            return null

        if (root.selectedDeviceId !== "") {
            for (var i = 0; i < root.devices.length; i++) {
                if (root.devices[i].id === root.selectedDeviceId)
                    return root.devices[i]
            }
        }

        for (var j = 0; j < root.devices.length; j++) {
            if (root.devices[j].available)
                return root.devices[j]
        }
        return root.devices[0]
    }

    signal requestRefresh()
    signal refreshRequested()
    signal shareRequested(string deviceId, var urls)
    signal deviceAction(string deviceId, string action, string successMessage)
    signal openSettings()

    closePolicy: PlasmaComponents3.Popup.CloseOnEscape |
        PlasmaComponents3.Popup.CloseOnPressOutside

    onOpened: root.requestRefresh()

    function actionEnabled() {
        return root.activeDevice !== null &&
            root.activeDevice.available && !root.busy
    }

    QtDialogs.FileDialog {
        id: fileDialog
        title: "Share files with device"
        fileMode: QtDialogs.FileDialog.OpenFiles
        onAccepted: {
            if (!root.activeDevice)
                return

            var urls = []
            for (var i = 0; i < selectedFiles.length; i++)
                urls.push(selectedFiles[i].toString())
            if (urls.length > 0)
                root.shareRequested(root.activeDevice.id, urls)
        }
    }

    background: Rectangle {
        color: root.theme.widgetBackgroundColor
        radius: 8
        border.color: root.theme.border
        border.width: 1
    }

    // The reference layout is intentionally compact: one device summary,
    // followed by six equally sized actions.
    component ActionTile: PlasmaComponents3.Button {
        id: tile

        Layout.fillWidth: true
        Layout.preferredHeight: 52
        Layout.minimumHeight: 52
        font.pointSize: 8
        display: PlasmaComponents3.Button.TextOnly

        background: Rectangle {
            color: tile.down ? Qt.alpha(root.theme.text, 0.16) :
                (tile.hovered ? Qt.alpha(root.theme.text, 0.09) : root.theme.surfaceAlt)
            radius: 6
            border.color: tile.hovered ? Qt.alpha(root.theme.text, 0.18) : "transparent"
            border.width: 1
        }

        contentItem: PlasmaComponents3.Label {
            text: tile.text
            color: tile.enabled ? root.theme.text : root.theme.subtext
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            maximumLineCount: 2
            font.pointSize: 8
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents3.Label {
                text: "KDE Connected Device"
                color: root.theme.text
                font.pointSize: 12
                Layout.fillWidth: true
            }

            Controls.ComboBox {
                visible: root.devices.length > 1
                model: root.devices
                textRole: "name"
                implicitWidth: 120
                currentIndex: {
                    if (!root.activeDevice)
                        return -1
                    for (var i = 0; i < root.devices.length; i++) {
                        if (root.devices[i].id === root.activeDevice.id)
                            return i
                    }
                    return -1
                }
                onActivated: index => root.selectedDeviceId = root.devices[index].id
            }

            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: root.activeDevice && root.activeDevice.available
                    ? root.theme.positive : root.theme.negative
                Layout.alignment: Qt.AlignVCenter
            }

            PlasmaComponents3.Button {
                icon.name: "view-refresh"
                display: PlasmaComponents3.Button.IconOnly
                enabled: !root.busy
                onClicked: root.refreshRequested()
                Controls.ToolTip.text: "Refresh device information"
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

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            Layout.minimumHeight: 140
            visible: root.activeDevice !== null
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 86
                Layout.minimumWidth: 86
                Layout.preferredHeight: 140
                Layout.minimumHeight: 140
                color: root.theme.surface
                radius: 4

                Image {
                    anchors.centerIn: parent
                    width: 56
                    height: 56
                    source: "../../icons/monitor-smartphone.svg"
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.9
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: root.theme.surfaceAlt
                radius: 6

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 7

                    PlasmaComponents3.Label {
                        text: root.activeDevice ? root.activeDevice.name : ""
                        color: root.theme.text
                        font.pointSize: 15
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        visible: root.activeDevice && root.activeDevice.batteryCharge >= 0
                        spacing: 8

                        Image {
                            source: "../../icons/battery-full.svg"
                            sourceSize: Qt.size(20, 20)
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                        }

                        PlasmaComponents3.Label {
                            text: root.activeDevice ? root.activeDevice.batteryCharge + "%" : ""
                            color: root.theme.text
                            font.pointSize: 11
                        }
                    }

                    RowLayout {
                        visible: root.activeDevice && root.activeDevice.networkLabel !== ""
                        spacing: 8

                        Image {
                            source: "../../icons/Wifi/wifi.svg"
                            sourceSize: Qt.size(20, 20)
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                        }

                        PlasmaComponents3.Label {
                            text: root.activeDevice ? root.activeDevice.networkLabel : ""
                            color: root.theme.text
                            font.pointSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    PlasmaComponents3.Label {
                        visible: root.activeDevice &&
                            root.activeDevice.batteryCharge < 0 &&
                            root.activeDevice.networkLabel === ""
                        text: root.activeDevice && root.activeDevice.available
                            ? "Connected" : "Paired, offline"
                        color: root.activeDevice && root.activeDevice.available
                            ? root.theme.positive : root.theme.subtext
                        font.pointSize: 9
                    }
                }
            }
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: root.checked && root.activeDevice === null
            text: !root.serviceAvailable
                ? "KDE Connect is unavailable or no devices are paired."
                : "No paired devices found."
            color: root.theme.subtext
            font.pointSize: 9
            wrapMode: Text.Wrap
        }

        GridLayout {
            columns: 3
            Layout.fillWidth: true
            Layout.fillHeight: true
            rowSpacing: 4
            columnSpacing: 4

            ActionTile {
                text: "Share files"
                enabled: root.actionEnabled()
                onClicked: fileDialog.open()
            }

            ActionTile {
                text: "Ring Device"
                enabled: root.actionEnabled()
                onClicked: root.deviceAction(root.activeDevice.id, "ring", "Ring requested")
            }

            ActionTile {
                text: "Access Files"
                enabled: root.actionEnabled()
                onClicked: root.deviceAction(root.activeDevice.id, "browse", "File browser opened")
            }

            ActionTile {
                text: "View Notifications"
                enabled: root.actionEnabled()
                onClicked: root.deviceAction(root.activeDevice.id, "notifications", "Notifications requested")
            }

            ActionTile {
                text: "Access Clipboard"
                enabled: root.actionEnabled()
                onClicked: root.deviceAction(root.activeDevice.id, "clipboard", "Clipboard sent")
            }

            ActionTile {
                text: "Disconnect"
                enabled: root.actionEnabled()
                onClicked: root.deviceAction(root.activeDevice.id, "unpair", "Device disconnected")
            }
        }
    }
}

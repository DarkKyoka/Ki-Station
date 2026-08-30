import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

import ".."

PlasmaComponents3.Popup {
    id: root

    implicitWidth: 350
    implicitHeight: 420
    width: implicitWidth
    height: implicitHeight

    property bool serviceAvailable: false
    property bool checked: false
    property bool busy: false
    property string statusMessage: ""
    property bool statusError: false
    property var devices: []
    property var notifications: []
    property bool notificationsChecked: false
    property var theme
    property string selectedDeviceId: ""
    property bool unpairConfirmationPending: false
    property bool showNotifications: false

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

    onOpened: {
        root.unpairConfirmationPending = false
        root.showNotifications = false
        root.requestRefresh()
    }
    onClosed: {
        root.unpairConfirmationPending = false
        root.showNotifications = false
    }

    function actionEnabled() {
        return root.activeDevice !== null &&
            root.activeDevice.available && !root.busy
    }

    function batteryIconSource(charge) {
        if (charge <= 15)
            return "../icons/Battery/battery-empty.svg"
        if (charge <= 40)
            return "../icons/Battery/battery-low.svg"
        if (charge <= 75)
            return "../icons/Battery/battery-medium.svg"
        return "../icons/battery-full.svg"
    }

    function providerLabel(provider) {
        var value = String(provider || "").trim()
        if (value === "")
            return ""
        if (value.toLowerCase() === "lan")
            return "Local network"
        if (value.toLowerCase() === "bluetooth")
            return "Bluetooth"
        return value
    }

    Timer {
        id: unpairConfirmationTimer
        interval: 4000
        repeat: false
        onTriggered: root.unpairConfirmationPending = false
    }

    QtDialogs.FileDialog {
        id: fileDialog
        title: root.activeDevice
            ? "Share files with " + root.activeDevice.name
            : "Share files with device"
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

    component ActionButton: PlasmaComponents3.Button {
        id: actionButton

        property string iconName: ""
        property bool primary: false
        property bool destructive: false

        Layout.fillWidth: true
        Layout.preferredHeight: 46
        Layout.minimumHeight: 46
        opacity: enabled ? 1 : 0.45

        background: Rectangle {
            radius: 5
            color: {
                if (actionButton.down)
                    return Qt.alpha(actionButton.destructive
                        ? root.theme.negative : root.theme.text, 0.2)
                if (actionButton.primary)
                    return actionButton.hovered
                        ? Qt.lighter(root.theme.accent, 1.12) : root.theme.accent
                if (actionButton.hovered)
                    return Qt.alpha(root.theme.text, 0.1)
                return root.theme.surfaceAlt
            }
            border.width: actionButton.primary ? 0 : 1
            border.color: actionButton.destructive
                ? Qt.alpha(root.theme.negative, 0.55)
                : Qt.alpha(root.theme.text, 0.12)
        }

        contentItem: RowLayout {
            spacing: 8

            Item { Layout.fillWidth: true }

            Kirigami.Icon {
                source: actionButton.iconName
                color: actionButton.primary ? root.theme.onAccent :
                    (actionButton.destructive ? root.theme.negative : root.theme.text)
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
            }

            PlasmaComponents3.Label {
                text: actionButton.text
                color: actionButton.primary ? root.theme.onAccent :
                    (actionButton.destructive ? root.theme.negative : root.theme.text)
                font.pointSize: 9
                elide: Text.ElideRight
            }

            Item { Layout.fillWidth: true }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30

            PlasmaComponents3.Button {
                visible: root.showNotifications
                icon.name: "arrow-left"
                display: PlasmaComponents3.Button.IconOnly
                onClicked: root.showNotifications = false
                Controls.ToolTip.text: "Back to device actions"
                Controls.ToolTip.visible: hovered
            }

            PlasmaComponents3.Label {
                text: root.showNotifications ? "Notifications" : "KDE Connect"
                color: root.theme.text
                font.bold: true
                font.pointSize: 12
                Layout.fillWidth: true
            }

            Controls.BusyIndicator {
                visible: root.busy || !root.checked
                running: visible
                implicitWidth: 20
                implicitHeight: 20
            }

            PlasmaComponents3.Button {
                icon.name: "view-refresh"
                display: PlasmaComponents3.Button.IconOnly
                enabled: !root.busy
                onClicked: {
                    if (root.showNotifications && root.activeDevice) {
                        root.deviceAction(root.activeDevice.id, "notifications",
                            "Notifications loaded")
                    } else {
                        root.refreshRequested()
                    }
                }
                Controls.ToolTip.text: root.showNotifications
                    ? "Refresh notifications" : "Refresh devices"
                Controls.ToolTip.visible: hovered
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            visible: root.activeDevice !== null && !root.showNotifications
            radius: 6
            color: root.theme.surfaceAlt
            border.width: 1
            border.color: root.activeDevice && root.activeDevice.available
                ? Qt.alpha(root.theme.positive, 0.35)
                : Qt.alpha(root.theme.text, 0.1)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Item {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: Qt.alpha(root.activeDevice && root.activeDevice.available
                            ? root.theme.positive : root.theme.subtext, 0.1)
                    }

                    ThemedIcon {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        source: "../icons/monitor-smartphone.svg"
                        color: root.activeDevice && root.activeDevice.available
                            ? root.theme.positive : root.theme.subtext
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Controls.ComboBox {
                        visible: root.devices.length > 1
                        Layout.fillWidth: true
                        Layout.maximumWidth: 210
                        model: root.devices
                        textRole: "name"
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

                    PlasmaComponents3.Label {
                        visible: root.devices.length <= 1
                        text: root.activeDevice ? root.activeDevice.name : ""
                        color: root.theme.text
                        font.bold: true
                        font.pointSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 5

                        Rectangle {
                            width: 7
                            height: 7
                            radius: 4
                            color: root.activeDevice && root.activeDevice.available
                                ? root.theme.positive : root.theme.subtext
                        }

                        PlasmaComponents3.Label {
                            text: root.activeDevice && root.activeDevice.available
                                ? "Connected" : "Paired, offline"
                            color: root.activeDevice && root.activeDevice.available
                                ? root.theme.positive : root.theme.subtext
                            font.pointSize: 9
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: root.activeDevice &&
                            (root.activeDevice.batteryCharge >= 0 ||
                             root.activeDevice.networkLabel !== "")

                        RowLayout {
                            visible: root.activeDevice && root.activeDevice.batteryCharge >= 0
                            spacing: 4

                            ThemedIcon {
                                source: root.activeDevice
                                    ? root.batteryIconSource(root.activeDevice.batteryCharge) : ""
                                color: root.theme.text
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                            }

                            PlasmaComponents3.Label {
                                text: root.activeDevice
                                    ? root.activeDevice.batteryCharge + "%" : ""
                                color: root.theme.text
                                font.pointSize: 9
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.activeDevice && root.activeDevice.networkLabel !== ""
                            spacing: 4

                            Kirigami.Icon {
                                source: "network-wireless-100"
                                color: root.theme.subtext
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 15
                            }

                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: root.activeDevice
                                    ? root.providerLabel(root.activeDevice.networkLabel) : ""
                                color: root.theme.subtext
                                font.pointSize: 9
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: statusLabel.implicitHeight + 14
            visible: root.statusMessage !== ""
            radius: 4
            color: Qt.alpha(root.statusError ? root.theme.negative : root.theme.info, 0.1)
            border.width: 1
            border.color: Qt.alpha(root.statusError
                ? root.theme.negative : root.theme.info, 0.25)

            PlasmaComponents3.Label {
                id: statusLabel
                anchors.fill: parent
                anchors.margins: 7
                text: root.statusMessage
                color: root.statusError ? root.theme.negative : root.theme.subtext
                font.pointSize: 8
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.activeDevice !== null && !root.showNotifications
            spacing: 6

            PlasmaComponents3.Label {
                text: "Actions"
                color: root.theme.subtext
                font.bold: true
                font.pointSize: 8
            }

            ActionButton {
                text: "Share files"
                iconName: "document-send"
                primary: true
                enabled: root.actionEnabled()
                onClicked: fileDialog.open()
            }

            GridLayout {
                columns: 2
                Layout.fillWidth: true
                rowSpacing: 6
                columnSpacing: 6

                ActionButton {
                    text: "Ring phone"
                    iconName: "call-start"
                    enabled: root.actionEnabled()
                    onClicked: root.deviceAction(
                        root.activeDevice.id, "ring", "Ring requested")
                }

                ActionButton {
                    text: "Browse files"
                    iconName: "folder-open"
                    enabled: root.actionEnabled()
                    onClicked: root.deviceAction(
                        root.activeDevice.id, "browse", "File browser opened")
                }

                ActionButton {
                    text: "Notifications"
                    iconName: "notifications"
                    enabled: root.actionEnabled()
                    onClicked: {
                        root.showNotifications = true
                        root.deviceAction(root.activeDevice.id, "notifications",
                            "Notifications loaded")
                    }
                }

                ActionButton {
                    text: "Send clipboard"
                    iconName: "edit-copy"
                    enabled: root.actionEnabled()
                    onClicked: root.deviceAction(
                        root.activeDevice.id, "clipboard", "Clipboard sent")
                }
            }

            Item { Layout.fillHeight: true }

            PlasmaComponents3.MenuSeparator { Layout.fillWidth: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                ActionButton {
                    text: root.unpairConfirmationPending ? "Confirm unpair" : "Unpair"
                    iconName: "edit-delete"
                    destructive: true
                    enabled: root.actionEnabled()
                    Layout.preferredHeight: 40
                    Layout.minimumHeight: 40
                    onClicked: {
                        if (!root.unpairConfirmationPending) {
                            root.unpairConfirmationPending = true
                            unpairConfirmationTimer.restart()
                            return
                        }
                        root.unpairConfirmationPending = false
                        root.deviceAction(
                            root.activeDevice.id, "unpair", "Device unpaired")
                    }
                }

                ActionButton {
                    text: "Open app"
                    iconName: "configure"
                    enabled: !root.busy
                    Layout.preferredHeight: 40
                    Layout.minimumHeight: 40
                    onClicked: {
                        root.close()
                        root.openSettings()
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.activeDevice !== null && root.showNotifications
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: root.activeDevice ? root.activeDevice.name : ""
                    color: root.theme.subtext
                    font.pointSize: 9
                    elide: Text.ElideRight
                }

                PlasmaComponents3.Label {
                    visible: root.notificationsChecked
                    text: root.notifications.length + " active"
                    color: root.theme.subtext
                    font.pointSize: 8
                }
            }

            Controls.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: root.notifications.length > 0

                ListView {
                    id: notificationList
                    model: root.notifications
                    spacing: 4
                    interactive: contentHeight > height

                    delegate: Rectangle {
                        width: notificationList.width
                        height: Math.max(58, notificationText.implicitHeight + 34)
                        radius: 5
                        color: root.theme.surfaceAlt
                        border.width: 1
                        border.color: Qt.alpha(root.theme.text, 0.1)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Kirigami.Icon {
                                source: "notifications"
                                color: root.theme.info
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 2
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                PlasmaComponents3.Label {
                                    Layout.fillWidth: true
                                    text: modelData.appName
                                    color: root.theme.text
                                    font.bold: true
                                    font.pointSize: 9
                                    elide: Text.ElideRight
                                }

                                PlasmaComponents3.Label {
                                    id: notificationText
                                    Layout.fillWidth: true
                                    text: modelData.text !== ""
                                        ? modelData.text : "Notification"
                                    color: root.theme.subtext
                                    font.pointSize: 9
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.notifications.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, 260)
                    spacing: 8

                    Controls.BusyIndicator {
                        visible: !root.notificationsChecked && root.busy
                        running: visible
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Kirigami.Icon {
                        visible: root.notificationsChecked || !root.busy
                        source: "notifications-disabled"
                        color: root.theme.subtext
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        Layout.alignment: Qt.AlignHCenter
                        opacity: 0.7
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: !root.notificationsChecked && root.busy
                            ? "Loading notifications"
                            : (root.statusError
                                ? "Notifications unavailable"
                                : "No active notifications")
                        color: root.theme.text
                        font.bold: true
                        font.pointSize: 10
                        horizontalAlignment: Text.AlignHCenter
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        visible: root.notificationsChecked && !root.statusError
                        text: "Check that Notification sync and Android notification access are enabled."
                        color: root.theme.subtext
                        font.pointSize: 8
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.activeDevice === null

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width, 260)
                spacing: 8

                Kirigami.Icon {
                    source: root.checked && !root.serviceAvailable
                        ? "network-disconnect" : "smartphone"
                    color: root.theme.subtext
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.75
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: !root.checked ? "Looking for devices" :
                        (!root.serviceAvailable ? "KDE Connect unavailable" : "No paired devices")
                    color: root.theme.text
                    font.bold: true
                    font.pointSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: !root.checked ? "" :
                        (!root.serviceAvailable
                            ? "Open KDE Connect to start the service and pair a device."
                            : "Pair a phone in KDE Connect, then refresh this panel.")
                    color: root.theme.subtext
                    font.pointSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 6

                    PlasmaComponents3.Button {
                        text: "Refresh"
                        icon.name: "view-refresh"
                        enabled: !root.busy
                        Layout.fillWidth: true
                        onClicked: root.refreshRequested()
                    }

                    PlasmaComponents3.Button {
                        text: "Open app"
                        icon.name: "configure"
                        enabled: !root.busy
                        Layout.fillWidth: true
                        onClicked: {
                            root.close()
                            root.openSettings()
                        }
                    }
                }
            }
        }
    }
}

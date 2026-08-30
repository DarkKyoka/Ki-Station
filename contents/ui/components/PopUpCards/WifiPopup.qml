import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.components as PlasmaComponents3

PlasmaComponents3.Popup {
    id: root

    width: 286
    height: root.selectedSsid !== "" && root.selectedRequiresPassword ? 430 : 390

    // TopPanel owns the nmcli process and passes its current state into this
    // component. Keeping the popup data-only makes it easy to reuse or restyle.
    property bool wifiEnabled: true
    property bool networkChecked: false
    property bool networkManagerAvailable: true
    property bool wifiAvailable: false
    property bool wifiScanning: false
    property bool wifiBusy: false
    property string wifiStatusMessage: ""
    property bool wifiStatusError: false
    property var networks: []
    property var ethernetConnections: []
    property var theme
    property string selectedSsid: ""
    property bool selectedRequiresPassword: false

    // Actions are sent back to TopPanel, which is the only component that
    // talks to NetworkManager.
    signal toggleWifi(bool enable)
    signal connectToNetwork(string ssid, string password)
    signal openSettings()
    signal requestRefresh()

    closePolicy: PlasmaComponents3.Popup.CloseOnEscape |
        PlasmaComponents3.Popup.CloseOnPressOutside

    // Open networks can be connected immediately. Secured networks stay
    // selected so the password form below can collect credentials first.
    function chooseNetwork(network) {
        if (root.wifiBusy || !network || network.active)
            return

        root.selectedSsid = network.ssid
        root.selectedRequiresPassword = network.requiresPassword === true
        passwordField.text = ""
        if (!root.selectedRequiresPassword)
            root.connectToNetwork(network.ssid, "")
    }

    function submitPassword() {
        if (root.selectedSsid === "" || passwordField.text === "" || root.wifiBusy)
            return
        root.connectToNetwork(root.selectedSsid, passwordField.text)
    }

    function clearSelection() {
        root.selectedSsid = ""
        root.selectedRequiresPassword = false
        passwordField.text = ""
    }

    // Refresh every time the menu opens so the list does not go stale.
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

        // Header: the switch is disabled while NetworkManager is busy.
        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents3.Label {
                text: "Wi-Fi"
                color: root.theme.text
                font.bold: true
                Layout.fillWidth: true
            }

            PlasmaComponents3.Switch {
                checked: root.wifiEnabled
                enabled: root.networkManagerAvailable && !root.wifiBusy
                onToggled: root.toggleWifi(checked)
            }
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: root.wifiStatusMessage !== ""
            text: root.wifiStatusMessage
            color: root.wifiStatusError ? root.theme.negative : root.theme.subtext
            font.pointSize: 8
            wrapMode: Text.Wrap
        }

        PlasmaComponents3.MenuSeparator { Layout.fillWidth: true }

        // Wired devices are shown above Wi-Fi when NetworkManager reports any.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.ethernetConnections.length > 0

            PlasmaComponents3.Label {
                text: "Wired"
                color: root.theme.subtext
                font.bold: true
                font.pointSize: 8
            }

            Repeater {
                model: root.ethernetConnections

                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: modelData.connected ? root.theme.positive : root.theme.subtext
                    }

                    PlasmaComponents3.Label {
                        text: modelData.connection
                        color: root.theme.text
                        font.bold: modelData.connected
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    PlasmaComponents3.Label {
                        text: modelData.device
                        color: root.theme.subtext
                        opacity: 0.65
                        font.pointSize: 8
                    }
                }
            }
        }

        // Explain why the list is empty or unavailable without hiding the
        // actual scan results.
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            visible: root.wifiScanning ||
                (root.networkChecked && !root.networkManagerAvailable) ||
                (root.networkChecked && !root.wifiAvailable && root.networks.length === 0)
            text: root.wifiScanning ? "Scanning for networks..." :
                (!root.networkManagerAvailable ? "NetworkManager is unavailable." :
                (!root.wifiAvailable ? "No Wi-Fi adapter detected." : "No networks found."))
            color: root.theme.subtext
            font.pointSize: 8
            wrapMode: Text.Wrap
        }

        // Network rows are deliberately simple: the SSID gets most of the
        // space, while security and signal strength remain visible at a glance.
        Controls.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: networkList
                model: root.networks
                spacing: 2
                interactive: contentHeight > height

                delegate: Controls.ItemDelegate {
                    width: networkList.width
                    height: 38
                    enabled: !root.wifiBusy && !modelData.active
                    highlighted: modelData.active

                    background: Rectangle {
                        radius: 4
                        color: modelData.active ? Qt.alpha(root.theme.positive, 0.12) :
                            (parent.hovered ? Qt.alpha(root.theme.text, 0.08) : "transparent")
                        border.color: modelData.active ? Qt.alpha(root.theme.positive, 0.35) : "transparent"
                        border.width: 1
                    }

                    contentItem: RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 7
                            height: 7
                            radius: 4
                            color: modelData.active ? root.theme.positive : "transparent"
                            border.color: modelData.active ? root.theme.positive : root.theme.subtext
                            border.width: modelData.active ? 0 : 1
                        }

                        PlasmaComponents3.Label {
                            text: modelData.ssid
                            color: root.theme.text
                            font.bold: modelData.active
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        PlasmaComponents3.Label {
                            text: modelData.requiresPassword ? "Secured" : "Open"
                            color: root.theme.subtext
                            font.pointSize: 8
                        }

                        PlasmaComponents3.Label {
                            text: modelData.signal + "%"
                            color: root.theme.subtext
                            font.pointSize: 8
                        }
                    }

                    onClicked: root.chooseNetwork(modelData)
                }
            }
        }

        // Selecting a secured row expands this form without opening another
        // dialog, keeping the interaction inside the same popup surface.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: root.selectedSsid !== "" && root.selectedRequiresPassword

            PlasmaComponents3.Label {
                text: "Password for " + root.selectedSsid
                color: root.theme.subtext
                font.pointSize: 8
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents3.TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    Layout.minimumHeight: 36
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    enabled: !root.wifiBusy
                    color: root.theme.text
                    selectByMouse: true

                    background: Rectangle {
                        color: root.theme.surface
                        radius: 4
                        border.color: passwordField.activeFocus ? root.theme.iconAction : root.theme.border
                        border.width: 1
                    }

                    Keys.onReturnPressed: root.submitPassword()
                }

                PlasmaComponents3.Button {
                    icon.name: "visibility"
                    display: PlasmaComponents3.Button.IconOnly
                    enabled: !root.wifiBusy
                    onClicked: passwordField.echoMode = passwordField.echoMode === TextInput.Password
                        ? TextInput.Normal : TextInput.Password
                }
            }

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents3.Button {
                    text: "Cancel"
                    enabled: !root.wifiBusy
                    onClicked: root.clearSelection()
                }

                PlasmaComponents3.Button {
                    text: "Connect"
                    Layout.fillWidth: true
                    enabled: passwordField.text !== "" && !root.wifiBusy
                    onClicked: root.submitPassword()
                }
            }
        }

        PlasmaComponents3.MenuSeparator { Layout.fillWidth: true }

        // Leave the detailed connection editor to the desktop network module.
        PlasmaComponents3.Button {
            Layout.fillWidth: true
            text: "Network Settings"
            onClicked: {
                root.close()
                root.openSettings()
            }
        }
    }
}

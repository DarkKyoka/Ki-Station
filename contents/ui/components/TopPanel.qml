import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasma5support as P5Support

    // Top header panel: avatar, welcome text, battery, and action buttons.
    // Absorbs all its own data sources: fully self-contained.
    Rectangle {
        id: root

        width: parent.width
        height: 118
        radius: 10
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: "#2E0015"

        // Command source: settings, power
        P5Support.DataSource {
            id: commandSource
            engine: "executable"
            connectedSources: []
            onNewData: (sourceName, data) => disconnectSource(sourceName)
        }

        // Avatar
        Item {
            id: pfpRect
            x: 8; y: 14
            width: 90; height: 90
            property string avatarSource: ""

            // Two-step lookup: whoami, check AccountsService, fallback to ~/.face just in case it fails
            P5Support.DataSource {
                id: accountsSource
                engine: "executable"
                connectedSources: []

                function exec(command) { connectSource(command) }

                onNewData: (sourceName, data) => {
                    if (data["exit code"] !== 0) { disconnectSource(sourceName); return }
                    var output = data["stdout"].trim()

                    if (sourceName === "whoami") {
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

            // Welcome text
            P5Support.DataSource {
                id: userSource
                engine: "executable"
                connectedSources: ["whoami"]
                onNewData: (sourceName, data) => {
                    infoCol.userName = data["stdout"].trim()
                }
            }

            property string userName: ""

            Text {
                text: "Hey, " + infoCol.userName + "!"
                font.pointSize: 16
                color: "white"
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

                Text  { text: batteryItem.percentage; color: "white"; font.pointSize: 11 }
                Image { source: "../icons/battery-full.svg" }
            }

            // Action buttons row
            Row {
                spacing: 7

                // Settings
                Item {
                    width: 22; height: 22
                    Image {
                        anchors.fill: parent
                        source: "../icons/settings.svg"
                        sourceSize: Qt.size(width, height)
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: commandSource.connectSource("systemsettings")
                    }
                }

                // WiFi, popup deferred to next session
                Item {
                    width: 22; height: 22
                    Image {
                        anchors.fill: parent
                        source: "../icons/Wifi/wifi.svg"
                        sourceSize: Qt.size(width, height)
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wifiPopup.open()
                    }
                    Popup { id: wifiPopup }
                }

                // Bluetooth, handler deferred to next session
                Image {
                    source: "../icons/Bluetooth/bluetooth_static.svg"
                    width: 22; height: 22
                }

                // KDE Connect, handler deferred to next session
                Image {
                    source: "../icons/monitor-smartphone.svg"
                    width: 22; height: 22
                }
            }
        }

        // Power button
        Item {
            width: 28; height: 28
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8

            Image {
                anchors.fill: parent
                source: "../icons/power.svg"
                sourceSize: Qt.size(width, height)
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
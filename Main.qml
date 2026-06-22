import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Shapes 1.15
import QtQuick.Effects
import QtQuick.Controls

Window {
    id: widgetMainWindow
    width: 430
    height: 650
    visible: true
    color: "#470020"
    title: qsTr("Ki Station")

    Column {
        y: 2
        spacing: 2
        anchors.horizontalCenter: parent.horizontalCenter

        // ===================== TOP PANEL =====================
        Rectangle {
            width: widgetMainWindow.width - 3
            height: 118
            radius: 10
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: "#2E0015"
            anchors.topMargin: 10

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12

                // pfp
                Item {
                    id: pfpRect
                    width: 90
                    height: 90

                    Image {
                        id: hiddenImg
                        source: "icons/Images/Makima.jpg"
                        visible: false
                        onStatusChanged: if (status === Image.Ready) pfpCanvas.requestPaint()
                    }

                    Canvas {
                        id: pfpCanvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.save()
                            ctx.beginPath()
                            ctx.arc(width / 2, height / 2, Math.min(width, height) / 2, 0, Math.PI * 2)
                            ctx.closePath()
                            ctx.clip()
                            ctx.drawImage(hiddenImg, 0, 0, width, height)
                            ctx.restore()
                        }
                    }

                    MouseArea { anchors.fill: parent; onClicked: console.log("pfp clicked") }
                }

                // user info
                Column {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Hey, User!"
                        font.pointSize: 16
                        color: "white"
                    }

                    Row {
                        spacing: 4
                        Text { text: "100%"; color: "white"; font.pointSize: 11 }
                        Text { text: "🔋"; font.pointSize: 11 }   // will replace with battery icon logic later
                    }


                    Row {
                        spacing: 10

                        // wifi
                        Image {
                            source:  "icons/Wifi/wifi.svg"  // TODO: replace — pre-color it white in the file
                            width: 22; height: 22
                        }

                        // bluetooth
                        Image {
                            source: "icons/Bluetooth/bluetooth_static.svg"      // TODO: replace — pre-color it blue/cyan in the file
                            width: 22; height: 22
                        }

                        // Kde Connect
                        Image {
                            property bool micMuted: true
                            source: micMuted ? "icons/mic-muted.svg" : "icons/mic.svg"
                            width: 18; height: 18
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // power button
                Item {
                    width: 36; height: 36
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        //anchors.fill: parent
                        y: -32
                        x: 12
                        source: "icons/power.svg"
                        sourceSize: Qt.size(width, height)


                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: console.log("Power Button")
                    }
                }
            }
        }

        RowLayout {
            spacing: 2
            width: widgetMainWindow.width - 3
            anchors.horizontalCenter: parent.horizontalCenter

            //              Weather & Time
            Rectangle {
                Layout.preferredWidth: 174
                height: 124
                radius: 0
                color: "#2E0015"

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 6

                    // City + date row
                    Row {
                        width: parent.width
                        Text {
                            width: 130
                            text: "Athens"
                            font.pointSize: 10
                            color: "white"
                        }
                        Item { width: 1 }
                        Text {
                            text: "19/6"
                            color: "white"
                            font.pointSize: 10
                        }
                    }

                    // Big time
                    Row {
                        spacing: 4
                        Text {
                            text: "7:10"
                            color: "white"
                            font.pointSize: 30
                            font.weight: 500
                        }
                        Text {
                            text: "pm"
                            color: "orange"
                            font.pointSize: 16
                            anchors.top: parent.top
                            anchors.topMargin: 17
                        }
                    }

                    // Temp + weather icon + status row
                    Row {
                        width: parent.width
                        spacing: 90

                        // x and Icon
                        Row{
                            Text {
                                text: "24"
                                color: "white"
                                font.pointSize: 12
                            }

                            Image {
                                source: "icons/Weathers/sun.svg"   // TODO: replace — pre-color it white/yellow
                                width: 16; height: 16
                                visible: true
                                y: 4
                            }
                        }


                        Item { Layout.fillWidth: true}

                        Text {
                            text: "Thunderstorm"
                            color: "white"
                            font.pointSize: 10
                            y: 2

                            anchors.right: parent.right
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            //                  Media Player
            Rectangle {
                Layout.fillWidth: true
                height: 124
                radius: 0
                color: "#2E0015"

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Album art + song info
                    Row {
                        spacing: 8

                        Rectangle {
                            id: albumArt
                            width: 65
                            height: 50
                            color: "#1A0009"   // placeholder square — swap for Image once you have art
                            radius: 4
                        }

                        // Media PLayer Info (name, artists, platform & State)
                        Column {
                            spacing: 2
                            Text {
                                text: "72 Seasons \\ Metallica"
                                color: "white"
                                font.pointSize: 9
                                width: 160
                                elide: Text.ElideRight
                            }


                            Text {
                                text: "Spotify"
                                color: "#1DB954"   // Spotify green
                                font.pointSize: 9
                            }

                            // Playback controls
                            Row {
                                spacing: 15
                                topPadding: 2

                                Image { source: "icons/MediaPlayer/skip-back.svg"; width: 14; height: 14 }
                                Image { source: "icons/MediaPlayer/pause.svg";    width: 14; height: 14 }
                                Image { source: "icons/MediaPlayer/skip-forward.svg"; width: 14; height: 14 }
                            }
                        }
                    }

                    // Media Progress bar
                    Column {
                        width: parent.width
                        spacing: 2

                        Rectangle {
                            width: parent.width
                            height: 12
                            radius: 8
                            color: "#140009"

                            Rectangle {
                                width: parent.width * 0.2   // 1:30 of 7:30 ≈ 20%
                                height: parent.height
                                radius: 8
                                color: "#3DDC6A"
                            }
                        }

                        Row {
                            spacing: 160
                            width: parent.width
                            Text { text: "1:30"; color: "white"; font.pointSize: 8 }

                            Text { text: "7:30"; color: "white"; font.pointSize: 8 }
                        }
                    }
                }
            }
        }

        // Bluetooth, KDE Connect & Volume / Brightness
        RowLayout {
            spacing: 2
            width: widgetMainWindow.width - 3
            anchors.horizontalCenter: parent.horizontalCenter

            //  Bluetooth
            Rectangle {
                color: "#2E0015"
                height: 130
                width: 97
                Layout.preferredWidth: 97

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 3


                    Image {
                        source: "icons/Bluetooth/bluetooth_static.svg"
                        width: 50
                        height: 58
                        sourceSize: Qt.size(width, height)
                        visible: true

                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    }

                    Text {
                        text: "Mi Band 6"
                        color: "white"
                        font.pointSize: 8
                        horizontalAlignment: Text.AlignHCenter

                        Layout.alignment: Qt.AlignHCenter

                    }
                }
            }

            //  KDE connect
            Rectangle {
                color: "#2E0015"
                height: 130
                width: 97
                Layout.preferredWidth: 97

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 3


                    Image {
                        source: "icons/monitor-smartphone.svg"
                        width: 50
                        height: 58
                        sourceSize: Qt.size(width, height)
                        visible: true

                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    }

                    Text {
                        text: "Mi Band 6"
                        color: "white"
                        font.pointSize: 8
                        horizontalAlignment: Text.AlignHCenter

                        Layout.alignment: Qt.AlignHCenter

                    }
                }


            }

            //Volume & Brightness
            Rectangle{
                Layout.fillWidth: true
                height: 130
                color: "#2E0015"

                // Volume Icon & bar
                Column{
                    anchors.margins: 10
                    anchors.fill: parent
                    spacing: 8

                    Column{
                        spacing: 0
                        Row{
                            spacing: 5
                            Image{
                                source: "icons/volume-2.svg"
                                width: 16
                                height: 16
                                y: 2
                                sourceSize: Qt.size(width, height)
                            }
                            Text{
                                text: "Volume"
                                color: "white"
                                font.pointSize: 10
                            }
                        }
                        // Custom Slider (volume )
                        Slider {
                            id: volumeBar
                            from: 0
                            to: 100
                            value: 25

                            width: 200
                            height: 30


                            background: Rectangle {
                                x: volumeBar.leftPadding
                                y: volumeBar.topPadding + volumeBar.availableHeight / 2 - height / 2
                                width: volumeBar.availableWidth
                                height: 12
                                radius: 30
                                color: "#140009"   // unfilled track color


                                // fill in
                                Rectangle {

                                    width: volumeBar.visualPosition * (volumeBar.availableWidth - 12) + 6   // fills based on current value
                                    height: parent.height

                                    radius: 12
                                    topRightRadius: value === 100 ? 30 : 12
                                    bottomRightRadius: value === 100 ? 30 : 12

                                    color: "#E6096C"   // filled portion — matches your media progress bar green
                                }


                            }
                            handle: Item {
                                x: volumeBar.leftPadding + volumeBar.visualPosition * (volumeBar.availableWidth - width)
                                y: volumeBar.topPadding + volumeBar.availableHeight / 2 - height / 2
                                width: 12
                                height: 12

                                Rectangle{
                                    color: "#a5004c"
                                    width: parent.width
                                    height: parent.height
                                    radius: parent.width * 2

                                    border.color: "#ffffff"
                                    border.width: 1


                                }
                                // intentionally empty — still needed so Slider has something to position,
                                // but it draws nothing since it has no color/children
                            }

                        }
                    }




                    Column{
                        spacing: 0

                        // Brightness icon and slider
                        Row{
                            spacing: 5
                            Image {
                                source: "icons/Weathers/sun.svg"
                                width: 16
                                height: 16
                                y: 2
                                sourceSize: Qt.size(width, height)
                            }
                            Text {
                                text: "Brightness"
                                color: "white"
                                font.pointSize: 10
                            }
                        }

                        // Custom Slider (Brightness)
                        Slider {
                            id: brightnessBar
                            from: 0
                            to: 100
                            value: 25

                            width: 200
                            height: 30


                            background: Rectangle {
                                x: brightnessBar.leftPadding
                                y: brightnessBar.topPadding + brightnessBar.availableHeight / 2 - height / 2
                                width: brightnessBar.availableWidth
                                height: 12
                                radius: 30
                                color: "#140009"   // unfilled track color


                                Rectangle {
                                    width: brightnessBar.visualPosition * (brightnessBar.availableWidth - 12) +6    // fills based on current value
                                    height: parent.height
                                    radius: 12

                                    topRightRadius: volumeBar.value === 100 ? 30 : 12
                                    bottomRightRadius: volumeBar.value === 100 ? 30 : 12
                                    color: "#E6096C"
                                }


                            }
                            handle: Item {
                                x: brightnessBar.leftPadding + brightnessBar.visualPosition * (brightnessBar.availableWidth - width)
                                y: brightnessBar.topPadding + brightnessBar.availableHeight / 2 - height / 2
                                width: 12
                                height: 12

                                Rectangle{
                                    color: "#a5004c"
                                    width: parent.width
                                    height: parent.height
                                    radius: parent.width * 2

                                    border.color: "#ffffff"
                                    border.width: 1


                                }
                                // intentionally empty — still needed so Slider has something to position,
                                // but it draws nothing since it has no color/children
                            }

                        }

                    }


                }


            }
        }





    }
}
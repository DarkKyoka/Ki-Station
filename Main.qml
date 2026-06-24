import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Shapes 1.15
import QtQuick.Effects
import QtQuick.Controls

import ki_Station 1.0


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

        //      TOP PANEL
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
                        source: "icons/Images/Makima.jpg"   //placeholder image
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

                // Welcome flavor text,  Battery state,  and State Badge Buttons
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
                        Image{source: "icons/battery-full.svg"}
                    }


                    Row {
                        spacing: 7

                        //Settings
                        Image{
                            source:  "icons/settings.svg"
                            width: 22; height: 22
                        }

                        // wifi
                        Image {
                            source:  "icons/Wifi/wifi.svg"
                            width: 22; height: 22
                        }

                        // bluetooth
                        Image {
                            source: "icons/Bluetooth/bluetooth_static.svg"
                            width: 22; height: 22
                        }

                        // Kde Connect
                        Image {
                            source: "icons/monitor-smartphone.svg"
                            width: 22; height: 22
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

        // Second Row of Panels (Weather-time & Media Player)
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
                    anchors.top: parent.top
                    anchors.margins: 10
                    width: parent.width - 20
                    spacing: 6

                    // City + date row
                    Row {
                        width: parent.width
                        Text {
                            width: 125
                            text: "Athens"
                            font.pointSize: 10
                            color: "white"
                        }
                        //Item { width: 1 }
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
                            color: appConstants.secondaryAccent
                            font.pointSize: 16
                            anchors.top: parent.top
                            anchors.topMargin: 17
                        }
                    }

                    // Temp + weather icon + status row
                    Row {
                        width: 150
                        height: 30
                        //spacing: 20

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

                            text: "Mist"
                            color: "white"


                            fontSizeMode: Text.Fit
                            font.pointSize: 10
                            minimumPointSize: 6

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
                    spacing: 20

                    // Album art + song info
                    Row {
                        spacing: 4


                        // placeholder, it will be replaced by the Albums cover image
                        Rectangle {
                            id: albumArt
                            width: 75
                            height: 55
                            color: "#1A0009"
                            radius: 4
                        }

                        // Media PLayer Info (name, artists, platform & State)
                        Column {
                            y: 3

                            spacing: 1
                            Text {
                                text: "72 Seasons"
                                color: "white"
                                font.pointSize: 10
                                width: 160
                                elide: Text.ElideRight
                            }

                            Text{
                                text: "Metallica"
                                color: "#B0B0B0"
                                font.pointSize: 8
                                width: 160
                                elide: Text.ElideRight
                            }


                            Text {
                                text: "Spotify"
                                color: "#9BFA78"
                                font.pointSize: 8
                            }

                        }
                    }


                    // Media Progress bar
                    Column {
                        width: parent.width
                        spacing: 2

                        Row {
                            //spacing: 0
                            width: parent.width
                            Text {
                                width: 78
                                text: "99:99:99";
                                color: "white";
                                horizontalAlignment: Text.AlignLeft
                                font.pointSize: 8

                                // DEBUG background
                                // Rectangle {
                                //     width: parent.width
                                //     height: parent.height
                                //     color: "white"
                                // }

                            }

                            //Media Controls
                            Row {
                                spacing: 15
                                topPadding: 2

                                Image { source: "icons/MediaPlayer/skip-back.svg"; width: 14; height: 14 }
                                Image { source: "icons/MediaPlayer/pause.svg";    width: 14; height: 14 }
                                Image { source: "icons/MediaPlayer/skip-forward.svg"; width: 14; height: 14 }
                            }


                            Text {
                                width: 78
                                text: "99:99:99";
                                color: "white";
                                horizontalAlignment: Text.AlignRight
                                font.pointSize: 8

                                // DEBUG background
                                // Rectangle {
                                //     width: parent.width
                                //     height: parent.height
                                //     color: "white"
                                // }

                            }
                        }
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


                    }
                }
            }
        }

        // DND, Mic button & Volume / Brightness
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
                    spacing: 6


                    Image {
                        source: "icons/DnD/bell-off.svg"
                        width: 60
                        height: 60
                        sourceSize: Qt.size(width, height)
                        visible: true

                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    }

                    Text {
                        text: "DnD: on"
                        color: "white"
                        font.pointSize: 8
                        horizontalAlignment: Text.AlignHCenter

                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: -35

                    }
                }
            }

            //  Mic Mute
            Rectangle {
                color: "#2E0015"
                height: 130
                width: 97
                Layout.preferredWidth: 97

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6


                    Image {
                        source: "icons/Mic/mic-on.svg"
                        width: 60
                        height: 60
                        sourceSize: Qt.size(width, height)
                        visible: true

                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    }

                    Text {
                        text: "Mic: Enabled"
                        color: "white"
                        font.pointSize: 8
                        horizontalAlignment: Text.AlignHCenter

                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: -35

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

                            }

                        }

                    }


                }


            }
        }





    }
}
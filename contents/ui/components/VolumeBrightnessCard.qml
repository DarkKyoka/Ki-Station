import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasma5support as P5Support


Rectangle {
    id: root

    Layout.fillWidth: true
    height: 130
    color: "#2E0015"

    property int brightnessMaxValue: 10000

    P5Support.DataSource {
        id: sliderSource
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            var out = data["stdout"].trim()

            if (sourceName.includes("get-sink-volume"))
                volumeBar.value = parseInt(out)

            if (sourceName.includes("brightnessMax"))
                root.brightnessMaxValue = parseInt(out)

            // Read actual brightness only after we know the max
            if (sourceName.includes("brightness") && !sourceName.includes("Max")) {
                if (root.brightnessMaxValue > 0)
                    brightnessBar.value = Math.round((parseInt(out) / root.brightnessMaxValue) * 100)
            }

            disconnectSource(sourceName)
        }

        Component.onCompleted: {
            connectSource("pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -1")
            connectSource("qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightnessMax")
            connectSource("qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightness")

        }
    }

    //Fire and forget source for volume and brightness
    P5Support.DataSource {
        id: commandSource
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
    }


    // Slider blueprint for re-using it
    // Avoids repeating the same background/handle block twice
    component StyledSlider: Slider {
        id: styledSlider
        from: 0
        to: 100
        height: 30

        background: Rectangle {
            x: styledSlider.leftPadding
            y: styledSlider.topPadding + styledSlider.availableHeight / 2 - height / 2
            width: styledSlider.availableWidth
            height: 12
            radius: 30
            color: "#140009"

            Rectangle {
                width: styledSlider.visualPosition * (styledSlider.availableWidth - 12) + 6
                height: parent.height
                radius: 12
                topRightRadius:    styledSlider.value === 100 ? 30 : 12
                bottomRightRadius: styledSlider.value === 100 ? 30 : 12
                color: "#E6096C"
            }
        }

        handle: Item {
            x: styledSlider.leftPadding + styledSlider.visualPosition * (styledSlider.availableWidth - width)
            y: styledSlider.topPadding + styledSlider.availableHeight / 2 - height / 2
            width: 12
            height: 12

            Rectangle {
                width: parent.width
                height: parent.height
                radius: parent.width * 2
                color: "#a5004c"
                border.color: "#ffffff"
                border.width: 1
            }
        }
    }

    // UI
    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        //Volume section
        Column {
            spacing: 0
            width: parent.width
            Row {
                spacing: 5
                Image {
                    source: "../icons/volume-2.svg"
                    width: 16
                    height: 16
                    y: 2
                    sourceSize: Qt.size(width, height)
                }
                Text {
                    text: "Volume"
                    color: "white"
                    font.pointSize: 10
                }
            }
            // Custom Slider (volume)
            StyledSlider {
                id: volumeBar
                width: parent.width
                value: 25
                onMoved: commandSource.connectSource(
                    "pactl set-sink-volume @DEFAULT_SINK@ " + Math.round(value) + "%"
                )
            }
        }

        // Brightness section
        Column {
            spacing: 0
            width: parent.width

            // Brightness icon
            Row {
                spacing: 5
                Image {
                    source: "../icons/Weathers/sun.svg"
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

            StyledSlider {
                id: brightnessBar
                width: parent.width
                value: 25
                onMoved: {
                    var raw = Math.round((value / 100) * root.brightnessMaxValue)
                    commandSource.connectSource(
                        "qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.setBrightness " + raw
                    )
                }
            }
        }
    }
}
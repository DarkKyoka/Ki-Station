import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Shapes 1.15
import QtQuick.Effects
import QtQuick.Controls

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: widgetMainWindow

    property int cardWidth: 430

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    fullRepresentation: Item {
        id: fullRepItem
        implicitWidth: backgroundRect.width
        Layout.preferredHeight: backgroundRect.height

        Rectangle {
            id: backgroundRect
            width: widgetMainWindow.cardWidth
            height: mainColumn.height + 4
            //anchors.fill: parent
            color: "#470020"


            Column {
                y: 2
                spacing: 2
                anchors.horizontalCenter: parent.horizontalCenter
                id: mainColumn

                //      TOP PANEL
                Rectangle {

                    width: widgetMainWindow.cardWidth - 3
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

                        Item {
                            id: pfpRect

                            width: 90
                            height: 90

                            property string avatarSource: ""

                            P5Support.DataSource {
                                id: accountsSource

                                engine: "executable"
                                connectedSources: []

                                function exec(command, id) {
                                    connectSource(command)
                                    sourceIds[id] = command
                                }

                                property var sourceIds: ({})
                                property string currentRequest: ""

                                onNewData: (sourceName, data) => {

                                    if (data["exit code"] !== 0) {
                                        console.log("Command failed:", sourceName)
                                        disconnectSource(sourceName)
                                        return
                                    }

                                    var output = data["stdout"].trim()

                                    console.log(sourceName, "=>", output)


                                    // Step 1: get user object
                                    if (sourceName === "users") {

                                        // Extract /org/freedesktop/Accounts/UserXXXX
                                        var userPath = output.match(/\/org\/freedesktop\/Accounts\/User[0-9]+/)[0]

                                        accountsSource.exec(
                                            "busctl get-property " +
                                            "org.freedesktop.Accounts " +
                                            userPath + " " +
                                            "org.freedesktop.Accounts.User " +
                                            "IconFile",
                                            "icon"
                                        )
                                    }


                                    // Step 2: get avatar path
                                    else if (sourceName === "icon") {

                                        // busctl returns:
                                        // s "/home/user/.face"

                                        var path = output.replace(/^s "/, "").replace(/"$/, "")

                                        console.log("Avatar path:", path)

                                        if (path.length > 0)
                                            pfpRect.avatarSource = "file://" + path
                                    }


                                    disconnectSource(sourceName)
                                }


                                Component.onCompleted: {

                                    exec(
                                        "busctl call " +
                                        "org.freedesktop.Accounts " +
                                        "/org/freedesktop/Accounts " +
                                        "org.freedesktop.Accounts " +
                                        "ListCachedUsers",
                                        "users"
                                    )
                                }
                            }


                            Rectangle {

                                anchors.fill: parent

                                radius: width / 2
                                clip: true


                                Image {

                                    anchors.fill: parent

                                    source: pfpRect.avatarSource

                                    fillMode: Image.PreserveAspectCrop


                                    onStatusChanged: {
                                        console.log("Image status:", status)
                                    }
                                }
                            }
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

                            //battery
                            Row {
                                visible: batteryItem.hasBattery
                                Item{
                                    id: batteryItem

                                    property int percentage: 0
                                    property bool charging: false
                                    property bool hasBattery: false

                                    P5Support.DataSource{
                                        id: pmSource
                                        engine: "powermanagement"
                                        connectedSources : ["Battery"]

                                        onDataChanged: {
                                            var battery = data["Battery"]
                                            if(battery && battery["Has battery"] != undefined){
                                                batteryItem.hasBattery = battery["Has Battery"]
                                                batteryItem.percent = battery["Percent"]
                                                batteryItem.charging = battery["State"] === "Charging"
                                            }
                                        }
                                    }
                                }

                                spacing: 4
                                Text { text: batteryItem.percentage; color: "white"; font.pointSize: 11 }
                                Image { source: "icons/battery-full.svg" }
                            }

                            Row {
                                spacing: 7

                                //Settings
                                Image {
                                    source: "icons/settings.svg"
                                    width: 22; height: 22
                                }

                                // wifi
                                Image {
                                    source: "icons/Wifi/wifi.svg"
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
                    width: widgetMainWindow.cardWidth - 3
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

                                //date text
                                Text {

                                    Item{
                                        id: date
                                        property string currentDate: Qt.formatDate(new Date(), "dd/MM")
                                    }

                                    text: date.currentDate
                                    color: "white"
                                    font.pointSize: 10
                                }
                            }



                            // time
                            Row {
                                //Time management in code
                                Item{
                                    id: timeCard
                                    property string currentTime: ""
                                    property string timePeriod;
                                    Timer{
                                        interval: 1000
                                        running: true
                                        repeat: true
                                        triggeredOnStart: true
                                        onTriggered: {
                                            var now = new Date()
                                            var fullTime = Qt.formatTime(now, "h:mm AP")
                                            var parts = fullTime.split(" ")
                                            timeCard.currentTime = parts[0]
                                            timeCard.timePeriod = parts[1]
                                        }
                                    }
                                }

                                spacing: 4
                                Text {
                                    text: timeCard.currentTime
                                    color: "white"
                                    font.pointSize: 28
                                    font.weight: 500
                                }
                                Text {
                                    text: timeCard.timePeriod
                                    color: "#FCAD35"
                                    font.pointSize: 16
                                    topPadding: 17
                                }
                            }


                            // Temp + weather icon + status row
                            RowLayout {
                                width: 150
                                height: 30

                                Item{
                                    id: tempItem
                                    property string temperature: "-"
                                    property string condition: "-"

                                    P5Support.DataSource{
                                        id: executable
                                        engine: "executable"
                                        connectedSources: []

                                        onNewData: (sourceName, data) => {
                                            if (data["exit code"] === 0) {
                                                var json = JSON.parse(data["stdout"])
                                                var temp = json.current.temperature_2m
                                                var code = json.current.weather_code

                                                tempItem.temperature = Math.round(temp) + "°"
                                                tempItem.condition = executable.codeToText(code)
                                            }
                                            disconnectSource(sourceName)
                                        }

                                        function exec(cmd){
                                            connectSource(cmd)
                                        }

                                        //weather code -> readable text
                                        function codeToText(code) {
                                            const map = {
                                                0: "Clear",
                                                1: "Mainly Clear",
                                                2: "Partly Cloudy",
                                                3: "Overcast",
                                                45: "Fog",
                                                48: "Fog",
                                                51: "Light Drizzle",
                                                53: "Drizzle",
                                                55: "Heavy Drizzle",
                                                61: "Light Rain",
                                                63: "Rain",
                                                65: "Heavy Rain",
                                                71: "Light Snow",
                                                73: "Snow",
                                                75: "Heavy Snow",
                                                80: "Rain Showers",
                                                81: "Rain Showers",
                                                82: "Violent Showers",
                                                95: "Thunderstorm",
                                                96: "Thunderstorm",
                                                99: "Severe Storm"
                                            }
                                            return map[code] !== undefined ? map[code] : "undefined"
                                        }
                                    }

                                    Timer {
                                        interval: 300000 // refresh every 5 minutes
                                        running: true
                                        repeat: true
                                        triggeredOnStart: true
                                        // it grabs the weather data from Open-Meteo
                                        onTriggered: executable.exec("curl -s 'https://api.open-meteo.com/v1/forecast?latitude=37.9838&longitude=23.7275&current=temperature_2m,weather_code'")
                                    }


                                }


                                RowLayout {
                                    spacing: 4
                                    Text {
                                        text: tempItem.temperature
                                        color: "white"
                                        font.pointSize: 12
                                    }

                                    Image {
                                        source: "icons/Weathers/sun.svg"
                                        width: 16; height: 16
                                        visible: true
                                        Layout.topMargin: 4
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: tempItem.condition
                                    color: "white"
                                    fontSizeMode: Text.Fit
                                    font.pointSize: 10
                                    minimumPointSize: 6
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

                                // placeholder rectangle image, it will be replaced by the Albums cover image
                                Rectangle {
                                    id: albumArt
                                    width: 75
                                    height: 55
                                    color: "#1A0009"
                                    radius: 4
                                }

                                // Media Player Info (name, artists, platform & State)
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

                                    Text {
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
                                    width: parent.width
                                    Text {
                                        width: 78
                                        text: "99:99:99"
                                        color: "white"
                                        horizontalAlignment: Text.AlignLeft
                                        font.pointSize: 8
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
                                        text: "99:99:99"
                                        color: "white"
                                        horizontalAlignment: Text.AlignRight
                                        font.pointSize: 8
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
                    width: widgetMainWindow.cardWidth - 3
                    anchors.horizontalCenter: parent.horizontalCenter

                    //  DnD
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
                    Rectangle {
                        Layout.fillWidth: true
                        height: 130
                        color: "#2E0015"

                        Column {
                            anchors.margins: 10
                            anchors.fill: parent
                            spacing: 8

                            Column {
                                spacing: 0
                                Row {
                                    spacing: 5
                                    Image {
                                        source: "icons/volume-2.svg"
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

                                        Rectangle {
                                            width: volumeBar.visualPosition * (volumeBar.availableWidth - 12) + 6
                                            height: parent.height
                                            radius: 12
                                            topRightRadius: volumeBar.value === 100 ? 30 : 12
                                            bottomRightRadius: volumeBar.value === 100 ? 30 : 12
                                            color: "#E6096C"   // filled portion
                                        }
                                    }
                                    handle: Item {
                                        x: volumeBar.leftPadding + volumeBar.visualPosition * (volumeBar.availableWidth - width)
                                        y: volumeBar.topPadding + volumeBar.availableHeight / 2 - height / 2
                                        width: 12
                                        height: 12

                                        Rectangle {
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

                            Column {
                                spacing: 0

                                // Brightness icon and slider
                                Row {
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
                                            width: brightnessBar.visualPosition * (brightnessBar.availableWidth - 12) + 6
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

                                        Rectangle {
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

                //System Stats & Alarm
                RowLayout {
                    spacing: 2
                    width: widgetMainWindow.cardWidth - 3
                    anchors.horizontalCenter: parent.horizontalCenter

                    // System Information Tab
                    Rectangle {
                        id: root

                        property real cpuUsage: 0.5        // 0.0 - 1.0
                        property real ramUsedGib: 2.5
                        property int ramTotalGib: 16
                        property int uploadMbps: 300
                        property int downloadMbps: 300

                        Layout.fillWidth: true
                        implicitHeight: 124
                        color: "#2E0015"

                        ColumnLayout {
                            id: contentLayout
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            // CPU usage row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Image {
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                    source: "icons/SystemInfo/cpu.svg"
                                }

                                Text {
                                    text: "CPU usage:"
                                    color: "white"
                                    font.pixelSize: 13
                                }

                                Item { Layout.fillWidth: true } // pushes the value to the right edge

                                Text {
                                    // Removed the unused anchors.right/verticalCenter here —
                                    // they were dead code: Text is a RowLayout child, and the
                                    // Item.fillWidth spacer above already pushes this to the right.
                                    text: Math.round(root.cpuUsage * 100) + "%"
                                    color: "white"
                                    font.pixelSize: 13
                                }
                            }

                            // RAM usage row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Image {
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                    source: "icons/SystemInfo/memory-stick.svg"
                                }

                                Text {
                                    text: "Ram usage:"
                                    color: "white"
                                    font.pixelSize: 13
                                }

                                Item { width: 25 }

                                Text {
                                    text: root.ramUsedGib.toFixed(1) + " / " + root.ramTotalGib + "gib"
                                    color: "white"
                                    font.pixelSize: 13
                                }
                            }

                            //  Network stats
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 5
                                    Image {
                                        Layout.preferredWidth: 18
                                        Layout.preferredHeight: 18
                                        source: "icons/SystemInfo/ethernet-port.svg"
                                    }
                                    Text {
                                        text: "Network Stats"
                                        color: "white"
                                        font.pixelSize: 13
                                    }
                                }

                                RowLayout {
                                    Layout.leftMargin: 35
                                    spacing: 16

                                    RowLayout {
                                        spacing: 4
                                        Text { text: "↑"; color: "#5ac8fa"; font.pixelSize: 13 }
                                        Text { text: root.uploadMbps + "mbps"; color: "#5ac8fa"; font.pixelSize: 13 }
                                    }

                                    RowLayout {
                                        spacing: 4
                                        Text { text: "↓"; color: "#5ac8fa"; font.pixelSize: 13 }
                                        Text { text: root.downloadMbps + "mbps"; color: "#5ac8fa"; font.pixelSize: 13 }
                                    }
                                }
                            }
                        }
                    }

                    // Alarm
                    Rectangle {
                        id: quickAlarmCard


                        Layout.fillWidth: true
                        implicitHeight: 124
                        color: "#2E0015"

                        property string alarmLabel: "Quick Alarm"
                        property string alarmTime: "99:99:99"
                        property bool alarmRunning: false

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing * 2
                            spacing: Kirigami.Units.smallSpacing

                            RowLayout {
                                Layout.fillWidth: true

                                PlasmaComponents3.Label {
                                    text: quickAlarmCard.alarmLabel
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.7
                                    color: "#e0c9b8"
                                    Layout.fillWidth: true
                                }

                                PlasmaComponents3.ToolButton {
                                    icon.name: "document-edit"
                                    onClicked: {
                                        // open alarm management popup/list here
                                    }
                                }
                            }

                            PlasmaComponents3.Label {
                                text: quickAlarmCard.alarmTime
                                font.pixelSize: Kirigami.Units.gridUnit * 1.6
                                font.bold: true
                                color: "#e0a458"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: Kirigami.Units.smallSpacing

                                PlasmaComponents3.ToolButton {
                                    Layout.fillWidth: true
                                    icon.name: "dialog-close"
                                    icon.color: "#d9534f"
                                    onClicked: quickAlarmCard.alarmRunning = false
                                }

                                PlasmaComponents3.ToolButton {
                                    Layout.fillWidth: true
                                    icon.name: quickAlarmCard.alarmRunning ? "media-playback-pause" : "media-playback-start"
                                    onClicked: quickAlarmCard.alarmRunning = !quickAlarmCard.alarmRunning
                                }
                            }
                        }
                    }
                }

                // Bash terminal panel
                Rectangle {
                    id: bashCard

                    width: widgetMainWindow.cardWidth
                    height : 150
                    color: "#2E0015"
                    radius: 0


                    property string promptUser: "User"
                    property string promptHost: "ThisPC"
                    property string currentPath: "~"
                    property var outputLines: []

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing * 2
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true

                            PlasmaComponents3.Label {
                                text: "Bash"
                                font.pixelSize: Kirigami.Units.gridUnit * 0.7
                                color: "#e0c9b8"
                                Layout.fillWidth: true
                            }

                            PlasmaComponents3.ToolButton {
                                icon.name: "edit-clear-history"
                                onClicked: bashCard.outputLines = []
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            background: Item{}

                            ColumnLayout {
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: bashCard.outputLines
                                    delegate: PlasmaComponents3.Label {
                                        text: modelData
                                        color: "#e0a458"
                                        font.family: "monospace"
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            PlasmaComponents3.Label {
                                text: bashCard.promptUser + "@" + bashCard.promptHost + ":" + bashCard.currentPath + "$"
                                color: "#e0a458"
                                font.family: "monospace"
                            }

                            PlasmaComponents3.TextField {
                                id: commandInput
                                Layout.fillWidth: true
                                placeholderText: "type a command..."
                                font.family: "monospace"
                                color: "#e0a458"

                                onAccepted: {

                                    bashCard.outputLines.push(
                                        bashCard.promptUser + "@" + bashCard.promptHost + "$ " + text
                                    )
                                    // runCommand(text) — hook this up to PlasmaCore.Process + Timer
                                    text = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

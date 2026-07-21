import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Shapes 1.15
import QtQuick.Effects
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support
import org.kde.notificationmanager as NotificationManager

PlasmoidItem {
    id: widgetMainWindow

    property int cardWidth: 430

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    fullRepresentation: Item {
        id: fullRepItem
        implicitWidth: backgroundRect.width
        Layout.preferredHeight: backgroundRect.height

        P5Support.DataSource {
            id: systemSource
            engine: "executable"
            connectedSources: []
            onNewData: (sourceName, data) => {
                disconnectSource(sourceName)
            }
        }

        // For Volume and Brightness
        P5Support.DataSource{
            id: sliderSource
            engine: "executable"
            connectedSources: []
            onNewData: (sourceName, data) => {
                var out = data["stdout"].trim()
                if (sourceName.includes("get-sink-volume")) {
                    volumeBar.value = parseInt(out)
                }
                if (sourceName.includes("brightnessMax")) {
                    brightnessMaxVal = parseInt(out)
                }
                if (sourceName.includes("brightness") && !sourceName.includes("Max")) {
                    if (brightnessMaxVal > 0)
                        brightnessBar.value = Math.round((parseInt(out) / brightnessMaxVal) * 100)
                }
                disconnectSource(sourceName)
            }
            property int brightnessMaxVal: 10000

            Component.onCompleted: {
                connectSource("pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -1")
                connectSource("qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightnessMax")
                connectSource("qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightness")
            }

        }

        // for Notification management , more specifically DnD
        NotificationManager.Settings {
            id: notifSettings
        }

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

                        //pfp
                        Item {
                            id: pfpRect
                            width: 90
                            height: 90
                            property string avatarSource: ""

                            P5Support.DataSource {
                                id: accountsSource
                                engine: "executable"
                                connectedSources: []

                                function exec(command) {
                                    connectSource(command)
                                }

                                onNewData: (sourceName, data) => {
                                    if (data["exit code"] !== 0) {
                                        //console.log("Avatar lookup step failed:", sourceName)
                                        disconnectSource(sourceName)
                                        return
                                    }
                                    var output = data["stdout"].trim()
                                    if (sourceName === "whoami") {
                                        var username = output
                                        accountsSource.exec(
                                            "test -f /var/lib/AccountsService/icons/" + username +
                                            " && echo /var/lib/AccountsService/icons/" + username +
                                            " || echo ~/.face"
                                        )
                                    }
                                    else {
                                        if (output.length > 0)
                                            pfpRect.avatarSource = "file://" + output
                                    }
                                    disconnectSource(sourceName)
                                }

                                Component.onCompleted: exec("whoami")
                            }

                            Image {
                                id: avatarImg
                                anchors.fill: parent
                                source: pfpRect.avatarSource
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: false

                                //onStatusChanged: console.log("Avatar status:", status)
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

                        // Welcome flavor text,  Battery state,  and State Badge Buttons
                        Column {
                            id: flavorTextCol
                            property string userName;

                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            P5Support.DataSource{
                                id: userSource
                                engine: "executable"
                                connectedSources: ["whoami"]

                                onNewData: function(sourceName, data){
                                    flavorTextCol.userName = data["stdout"].trim()
                                }
                            }

                            // flavor welcome text
                            Text {
                                text: "Hey, " + flavorTextCol.userName + "!"
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
                                            if(battery && battery["Has Battery"] !== undefined){
                                                batteryItem.hasBattery = battery["Has Battery"]
                                                batteryItem.percentage = battery["Percent"] !== undefined ? battery["Percent"] : 0
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
                                Item {
                                    width: 22; height: 22

                                    Image {
                                        anchors.fill: parent
                                        source: "icons/settings.svg"
                                        sourceSize: Qt.size(width, height)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: systemSource.connectSource("systemsettings")
                                    }
                                }

                                // wifi
                                Item {
                                    width: 22; height: 22

                                    Image {
                                        anchors.fill: parent
                                        source: "icons/Wifi/wifi.svg"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: wifiPopup.open()
                                    }

                                    Popup {
                                        id: wifiPopup
                                        // your mini panel content here
                                    }
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


                    }
                    // power button
                    Item {
                        width: 28; height: 28
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8

                        Image {
                            anchors.fill: parent
                            source: "icons/power.svg"
                            sourceSize: Qt.size(width, height)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                systemSource.connectSource(
                                    "qdbus6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptAll"
                                )
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
                        id: mediaCard


                        Layout.fillWidth: true
                        height: 124
                        radius: 0
                        color: "#2E0015"

                        property string artUrl: ""
                        property string videoUrl: ""
                        property string activePlayer: ""

                        property string title: "Nothing Playing"
                        property string artist: ""
                        property string album: ""
                        property string player: ""
                        property bool isPlaying: false
                        property real position: 0      // Ms
                        property real duration: 0      // Ms
                        property real progress: duration > 0 ? position / duration : 0

                        property bool hasPosition: position > 1000000

                        function getThumbnail(url){
                            var id = ""
                            var idx = url.indexOf("v=")
                            if (idx !== -1) {
                                id = url.substring(idx + 2)
                                var amp = id.indexOf("&")
                                if (amp !== -1) id = id.substring(0, amp)
                            }
                            if (id !== "") {
                                return "https://img.youtube.com/vi/" + id + "/mqdefault.jpg"
                            }
                            return ""
                        }

                        //Converts Ms to Minutes : Seconds format
                        function formatTime(us){
                            var s = Math.floor(us / 1000000)
                            var m = Math.floor(s / 60)
                            s = s % 60

                            return m + ":" + (s < 10 ? "0" : "") + s
                        }

                        P5Support.DataSource{
                            id: mediaSource
                            engine: "executable"
                            connectedSources: []
                            onNewData: (sourceName, data) => {
                                var out = data["stdout"].trim()
                                //console.log("sourceName:", sourceName, "| out:", out)  // add this

                                if (sourceName.includes("metadata --format")) {
                                    var parts = out.split("|")
                                    if (parts[0] === "") return

                                    mediaCard.activePlayer = parts[0] || ""
                                    mediaCard.title  = parts[1] || "Nothing Playing"
                                    mediaCard.artist = parts[2] || ""
                                    mediaCard.player = parts[0] || ""
                                    mediaCard.videoUrl = parts[5] || ""

                                    var art = parts[4] || ""
                                    var pageUrl = parts[5] || ""

                                    // Firefox sets artUrl to the watch page URL, not an image — ignore it
                                    if (art.includes("youtube.com/watch") || art.includes("youtu.be/")) {
                                        art = ""
                                    }

                                    // Derive thumbnail from page URL
                                    if (art === "" && pageUrl !== "") {
                                        art = mediaCard.getThumbnail(pageUrl)
                                    }

                                    if (art !== "") mediaCard.artUrl = art
                                }
                                if (sourceName.includes("playerctl status")) {
                                    mediaCard.isPlaying = out === "Playing"
                                }
                                if (sourceName.includes("playerctl metadata mpris:length")) {
                                    var len = parseFloat(out)

                                    if (!isNaN(len) && len > 0) {
                                        mediaCard.duration = len
                                    }
                                }
                                if (sourceName.includes("playerctl position")) {
                                    var sec = parseFloat(out)

                                    if (!isNaN(sec)) {
                                        mediaCard.position = sec * 1000000
                                    }
                                }
                                disconnectSource(sourceName)
                            }

                            function refresh() {
                                connectSource("playerctl metadata --format '{{playerName}}|{{title}}|{{artist}}|{{album}}|{{mpris:artUrl}}|{{xesam:url}}'")
                                connectSource("playerctl status")
                                connectSource("playerctl metadata mpris:length")
                                connectSource("playerctl position")
                            }
                        }


                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: mediaSource.refresh()
                        }

                        // Refresh every Second
                        Timer{
                            interval: 1000
                            running: mediaCard.isPlaying && !mediaCard.hasPosition
                            repeat: true
                            onTriggered: {
                                if (!mediaCard.hasPosition) {
                                    mediaCard.position += 1000000  // add 1 second in microseconds
                                }
                            }
                        }

                        Timer {
                            id: seekRefresh
                            interval: 200
                            repeat: false

                            onTriggered: mediaSource.refresh()
                        }

                        onTitleChanged: {
                            if (!mediaCard.hasPosition) {
                                mediaCard.position = 0
                            }
                        }
                        onArtUrlChanged: console.log("artUrl changed to:", mediaCard.artUrl)


                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 20

                            // Album art + song info
                            Row {
                                spacing: 4

                                // Album - Video Image
                                Item {
                                    id: albumArt
                                    width: 75
                                    height: 55

                                    Image {
                                        id: albumArtImg
                                        anchors.fill: parent
                                        source: mediaCard.artUrl
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                        visible: false
                                    }

                                    Rectangle {
                                        id: albumArtMask
                                        anchors.fill: parent
                                        radius: 8
                                        visible: false
                                    }

                                    OpacityMask {
                                        anchors.fill: albumArtImg
                                        source: albumArtImg
                                        maskSource: albumArtMask
                                    }

                                    // Fallback background when no image
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: "#1A0009"
                                        visible: mediaCard.artUrl === "" || albumArtImg.status !== Image.Ready
                                        z: -1
                                    }
                                }

                                // Media Player Info (name, artists, platform & State)
                                Column {
                                    y: 3
                                    spacing: 1
                                    Text {
                                        text: mediaCard.title
                                        color: "white"
                                        font.pointSize: 10
                                        width: 160
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: mediaCard.artist
                                        color: "#B0B0B0"
                                        font.pointSize: 8
                                        width: 160
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: mediaCard.player
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
                                        text: mediaCard.formatTime(
                                            progressBar.pressed ? progressBar.value : mediaCard.position
                                        )
                                        color: "white"
                                        horizontalAlignment: Text.AlignLeft
                                        font.pointSize: 8
                                        width: 78
                                    }

                                    //Media Controls
                                    Row {
                                        spacing: 15
                                        topPadding: 2

                                        Image {
                                            source: "icons/MediaPlayer/skip-back.svg";
                                            width: 14
                                            height: 14

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: systemSource.connectSource("playerctl -p " + mediaCard.activePlayer + " previous")
                                            }

                                        }
                                        Image {
                                            source: mediaCard.isPlaying ? "icons/MediaPlayer/pause.svg" : "icons/MediaPlayer/play.svg"
                                            width: 14;
                                            height: 14

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: systemSource.connectSource("playerctl -p " + mediaCard.activePlayer + " play-pause")
                                            }

                                        }
                                        Image {
                                            source: "icons/MediaPlayer/skip-forward.svg";
                                            width: 14;
                                            height: 14

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: systemSource.connectSource("playerctl -p " + mediaCard.activePlayer + " next")
                                            }
                                        }


                                    }

                                    Text {
                                        text: mediaCard.title === "Nothing Playing" ? "--:--" : mediaCard.formatTime(mediaCard.duration)
                                        color: "white"
                                        horizontalAlignment: Text.AlignRight
                                        font.pointSize: 8
                                        width: 78
                                    }
                                }
                                Slider {
                                    id: progressBar
                                    width: parent.width
                                    height: 12
                                    from: 0
                                    to: mediaCard.duration
                                    value: mediaCard.position

                                    Connections {
                                        target: mediaCard
                                        function onPositionChanged(){
                                            if(!progressBar.pressed){
                                                progressBar.value = mediaCard.position
                                            }
                                        }

                                        function onDurationChanged() {
                                            progressBar.to = mediaCard.duration
                                        }
                                    }

                                    onPressedChanged: {
                                        if (!pressed) {
                                            mediaCard.position = value

                                            var seconds = value / 1000000

                                            systemSource.connectSource(
                                                "playerctl -p " + mediaCard.activePlayer +
                                                " position " + seconds
                                            )

                                            seekRefresh.restart()
                                      }
                                    }
                                    Binding {
                                        target: progressBar
                                        property: "value"
                                        value: mediaCard.position
                                        when: !progressBar.pressed
                                    }


                                    background: Rectangle {
                                        x: progressBar.leftPadding
                                        y: progressBar.topPadding + progressBar.availableHeight / 2 - height / 2
                                        width: progressBar.availableWidth
                                        height: 12
                                        radius: 8
                                        color: "#140009"

                                        Rectangle {
                                            width: progressBar.visualPosition * parent.width
                                            height: parent.height
                                            radius: 8
                                            color: "#3DDC6A"
                                        }
                                    }

                                    handle: Item { width: 0; height: 0 } // invisible handle
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
                        id: dndCard

                        color: "#2E0015"
                        height: 130
                        width: 97
                        Layout.preferredWidth: 97

                        property bool dndActive: false

                        // Refresh state every 1/2 of second and on startup
                        Timer {
                            interval: 500
                            running: true
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: dndCard.dndActive = notifSettings.notificationsInhibitedUntil > new Date()
                        }



                        // Content
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 6

                            Image {
                                source: dndCard.dndActive ? "icons/DnD/bell-off.svg" : "icons/DnD/bell.svg"
                                width: 60; height: 60
                                sourceSize: Qt.size(width, height)
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            }

                            Text {
                                text: dndCard.dndActive ? "DnD: On" : "DnD: Off"
                                color: "white"
                                font.pointSize: 8
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: -35
                            }
                        }

                        // The interaction logic of the panel
                        MouseArea {


                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("DnD clicked, current state:", dndCard.dndActive)
                                if (notifSettings.notificationsInhibitedUntil > new Date()) {
                                    notifSettings.notificationsInhibitedUntil = new Date(0)
                                } else {
                                    var future = new Date()
                                    future.setFullYear(future.getFullYear() + 10)
                                    notifSettings.notificationsInhibitedUntil = future
                                }
                                notifSettings.save()    // saves to config
                            }
                        }
                    }

                    //  Mic Mute
                    Rectangle {
                        id: micCard

                        color: "#2E0015"
                        height: 130
                        width: 97
                        Layout.preferredWidth: 97

                        property bool isMuted

                        //checks for mic status once per 2 seconds
                        Timer{
                            interval: 2000
                            running: true
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: micSource.connectSource("pactl get-source-mute @DEFAULT_SOURCE@")
                        }

                        P5Support.DataSource{
                            id: micSource
                            engine: "executable"
                            connectedSources: []
                            onNewData: (sourceName, data) => {
                                var out = data["stdout"].trim()
                                micCard.isMuted = out.includes("yes")
                                disconnectSource(sourceName)
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 6

                            //icon handle
                            Image {
                                source: micCard.isMuted ? "icons/Mic/mic-on.svg" : "icons/Mic/mic-off.svg"
                                width: 60
                                height: 60
                                sourceSize: Qt.size(width, height)
                                visible: true
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            }

                            //state
                            Text {
                                text: micCard.isMuted ? "Mic: Enabled" : "Mic: Disabled"
                                color: "white"
                                font.pointSize: 8
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: -35
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var cmd = micCard.isMuted
                                    ? "pactl set-source-mute @DEFAULT_SOURCE@ 0"
                                    : "pactl set-source-mute @DEFAULT_SOURCE@ 1"
                                micCard.isMuted = !micCard.isMuted
                                systemSource.connectSource(cmd)
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

                                    onMoved: {
                                        systemSource.connectSource("pactl set-sink-volume @DEFAULT_SINK@ " + Math.round(value) + "%")
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

                                    onMoved: {
                                        var raw = Math.round((value / 100) * sliderSource.brightnessMaxVal)
                                        systemSource.connectSource("qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.setBrightness " + raw)
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
                    height: 150
                    color: "#2E0015"
                    radius: 0

                    property string promptUser: "User"
                    property string promptHost: "ThisPC"
                    property string currentPath: "~"
                    property var outputLines: []

                    // Runs shell commands and appends their output to outputLines
                    P5Support.DataSource {
                        id: promptSource
                        engine: "executable"
                        connectedSources: []

                        onNewData: (sourceName, data) => {
                            var stdout = data["stdout"].trim()
                            var stderr = data["stderr"].trim()

                            // Intercept startup commands — set prompt, don't print output
                            if (sourceName === "whoami") {
                                bashCard.promptUser = stdout
                                disconnectSource(sourceName)
                                return
                            }
                            if (sourceName === "hostname") {
                                bashCard.promptHost = stdout
                                disconnectSource(sourceName)
                                return
                            }

                            // Everything else goes to the output stream
                            if (stdout.length > 0) {
                                var lines = bashCard.outputLines.slice()
                                lines.push(stdout)
                                bashCard.outputLines = lines
                            }
                            if (stderr.length > 0) {
                                var lines = bashCard.outputLines.slice()
                                lines.push("error: " + stderr)
                                bashCard.outputLines = lines
                            }

                            disconnectSource(sourceName)
                        }

                        Component.onCompleted: {
                            connectSource("whoami")
                            connectSource("hostname")
                        }

                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing * 2
                        spacing: 0

                        // Header row (Bash label + clear button)
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
                                onClicked: {
                                    bashCard.outputLines = []
                                }
                            }
                        }

                        // Input line
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: bashCard.promptUser + "@" + bashCard.promptHost + ":" + bashCard.currentPath + "$"
                                color: "#6AED0C"
                                font.family: "monospace"
                                font.pixelSize: 10
                            }

                            PlasmaComponents3.TextField {
                                id: commandInput
                                Layout.fillWidth: true
                                placeholderText: ""
                                font.family: "monospace"
                                font.pixelSize: 10
                                color: "#e0a458"

                                // Blend into the terminal — no border, no background
                                background: Item {}

                                onAccepted: {
                                    var cmd = text.trim()
                                    if (cmd.length === 0) return

                                    var lines = bashCard.outputLines.slice()
                                    lines.push(bashCard.promptUser + "@" + bashCard.promptHost + ":~$ " + cmd)
                                    bashCard.outputLines = lines

                                    promptSource.connectSource(cmd)   // was bashSource

                                    text = ""
                                }
                            }
                        }

                        // Output screen with ListView auto-scrolls to bottom on new lines
                        ListView {
                            id: outputView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: bashCard.outputLines
                            spacing: 0

                            // No background — inherit parent card color
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                            }

                            delegate: Text {
                                width: outputView.width
                                text: modelData
                                color: "#e0a458"
                                font.family: "monospace"
                                font.pixelSize: 8
                                wrapMode: Text.Wrap
                            }

                            // Auto-scroll to bottom whenever a new line is added
                            onCountChanged: positionViewAtEnd()
                        }


                    }
                }
            }
        }
    }
}

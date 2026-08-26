import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasma5support as P5Support


Rectangle {
    id: root

    Layout.preferredWidth: 174
    height: 124
    radius: 0
    color: "#2E0015"

    property string temperature: "-"
    property string condition: "-"

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

    // Data weather source
    P5Support.DataSource{
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (data["exit code"] === 0) {
                var json = JSON.parse(data["stdout"])
                var temp = json.current.temperature_2m
                var code = json.current.weather_code

                root.temperature = Math.round(temp) + "°"
                root.condition = executable.codeToText(code)
            }
            disconnectSource(sourceName)
        }

        function exec(cmd){
            connectSource(cmd)
        }


    }

    //refresh timer
    Timer {
        interval: 300000 // refresh every 5 minutes the weather data
        running: true
        repeat: true
        triggeredOnStart: true
        // it grabs the weather data from Open-Meteo
        onTriggered: executable.exec("curl -s 'https://api.open-meteo.com/v1/forecast?latitude=37.9838&longitude=23.7275&current=temperature_2m,weather_code'")
    }

    // UI
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

            RowLayout {
                spacing: 4
                Text {
                    text: root.temperature
                    color: "white"
                    font.pointSize: 12
                }

                Image {
                    source: "../icons/Weathers/sun.svg"
                    width: 16; height: 16
                    visible: true
                    Layout.topMargin: 4
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.condition
                color: "white"
                fontSizeMode: Text.Fit
                font.pointSize: 10
                minimumPointSize: 6
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasma5support as P5Support


Rectangle {
    id: root

    Layout.preferredWidth: 174
    height: 124
    radius: 0
    color: theme.surface

    property string temperature: "-"
    property string condition: "-"
    property string locationName: "Locating..."
    property real latitude: 0
    property real longitude: 0
    property bool locationReady: false
    property var theme

    readonly property string locationQuery: "curl -4 -fsSL --max-time 10 -A 'Ki-Station/1.0' 'https://ipinfo.io/json'"
    property string weatherQuery: ""

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

    function refreshWeather() {
        if (!root.locationReady)
            return

        root.weatherQuery = "curl -fsSL --max-time 10 'https://api.open-meteo.com/v1/forecast?latitude=" +
                            root.latitude.toFixed(4) + "&longitude=" +
                            root.longitude.toFixed(4) +
                            "&current=temperature_2m,weather_code'"
        executable.exec(root.weatherQuery)
    }

    // Data weather source
    P5Support.DataSource{
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            var output = (data["stdout"] || "").trim()

            if (sourceName === root.locationQuery) {
                if (!root.locationReady)
                    root.locationName = "Location unavailable"

                if (data["exit code"] === 0) {
                    try {
                        var location = JSON.parse(output)
                        var coordinates = String(location.loc || "").split(",")
                        var resolvedLatitude = location.latitude !== undefined
                                ? Number(location.latitude) : Number(coordinates[0])
                        var resolvedLongitude = location.longitude !== undefined
                                ? Number(location.longitude) : Number(coordinates[1])

                        if (resolvedLatitude >= -90 && resolvedLatitude <= 90 &&
                            resolvedLongitude >= -180 && resolvedLongitude <= 180) {
                            root.latitude = resolvedLatitude
                            root.longitude = resolvedLongitude
                            root.locationName = location.city || location.region ||
                                                 location.country_name || "Unknown location"
                            root.locationReady = true
                            root.refreshWeather()
                        }
                    } catch (error) {
                        // Keep the unavailable state when the geolocation response is invalid.
                    }
                }
            } else if (sourceName === root.weatherQuery && data["exit code"] === 0) {
                try {
                    var weather = JSON.parse(output)
                    var temp = weather.current.temperature_2m
                    var code = weather.current.weather_code

                    root.temperature = Math.round(temp) + "°"
                    root.condition = root.codeToText(code)
                } catch (error) {
                    // Keep the last valid weather values when the response is invalid.
                }
            }
            disconnectSource(sourceName)
        }

        function exec(cmd){
            connectSource(cmd)
        }

    }

    // Resolve the user's area periodically in case the device changes networks.
    Timer {
        id: locationRefreshTimer
        interval: 3600000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        // Start with the location lookup; weather starts after coordinates are resolved.
        onTriggered: executable.exec(root.locationQuery)
    }

    // Refresh weather every five minutes after the user's location is known.
    Timer {
        id: weatherRefreshTimer
        interval: 300000
        running: root.visible && root.locationReady
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshWeather()
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
                text: root.locationName
                elide: Text.ElideRight
                font.pointSize: 10
                color: theme.text
            }

            //date text
            Text {

                Item{
                    id: date
                    property string currentDate: Qt.formatDate(new Date(), "dd/MM")
                }

                text: date.currentDate
                color: theme.text
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
                    running: root.visible
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
                color: theme.text
                font.pointSize: 28
                font.weight: 500
            }
            Text {
                text: timeCard.timePeriod
                color: theme.neutral
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
                    color: theme.text
                    font.pointSize: 12
                }

                ThemedIcon {
                    source: "../icons/Weathers/sun.svg"
                    width: 16; height: 16
                    color: theme.weatherIconColor
                    visible: true
                    Layout.topMargin: 4
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.condition
                color: theme.text
                fontSizeMode: Text.Fit
                font.pointSize: 10
                minimumPointSize: 6
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}

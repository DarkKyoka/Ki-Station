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

import "components"

PlasmoidItem {
    id: widgetMainWindow

    property int cardWidth: 430

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Persistent media state
    // Lives at PlasmoidItem level so it survives popup open/close cycles.
    // fullRepresentation reads from here and shows data instantly on open.
    QtObject {
        id: mediaState

        property string activePlayer: ""
        property string title:        "Nothing Playing"
        property string artist:       ""
        property string album:        ""
        property string player:       ""
        property string artUrl:       ""
        property string videoUrl:     ""
        property bool   isPlaying:    false
        property real   position:     0       // microseconds
        property real   duration:     0       // microseconds
        property real   progress:     duration > 0 ? position / duration : 0
        property bool   hasPosition:  position > 1000000
        property int    artRefreshTick: 0

        function getThumbnail(url) {
            var idx = url.indexOf("v=")
            if (idx === -1) return ""
            var id = url.substring(idx + 2)
            var amp = id.indexOf("&")
            if (amp !== -1) id = id.substring(0, amp)
            return id !== "" ? "https://img.youtube.com/vi/" + id + "/mqdefault.jpg" : ""
        }

        // Converts microseconds to m:ss
        function formatTime(us) {
            var s = Math.floor(us / 1000000)
            var m = Math.floor(s / 60)
            s = s % 60
            return m + ":" + (s < 10 ? "0" : "") + s
        }
    }

    P5Support.DataSource {
        id: mediaSource
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            var out = data["stdout"].trim()

            if (sourceName.includes("metadata --format")) {
                var parts = out.split("|")
                if (parts[0] === "") { disconnectSource(sourceName); return }

                mediaState.activePlayer = parts[0] || ""
                mediaState.title        = parts[1] || "Nothing Playing"
                mediaState.artist       = parts[2] || ""
                mediaState.player       = parts[0] || ""
                mediaState.videoUrl     = parts[5] || ""

                var art     = parts[4] || ""
                var pageUrl = parts[5] || ""

                // Firefox sets artUrl to the watch page — not an image, ignore it
                if (art.includes("youtube.com/watch") || art.includes("youtu.be/"))
                    art = ""

                // Derive thumbnail from the page URL instead
                if (art === "" && pageUrl !== "")
                    art = mediaState.getThumbnail(pageUrl)

                if (art !== "") mediaState.artUrl = art
            }
            if (sourceName.includes("playerctl status")) {
                mediaState.isPlaying = out === "Playing"
            }
            if (sourceName.includes("playerctl metadata mpris:length")) {
                var len = parseFloat(out)
                if (!isNaN(len) && len > 0) mediaState.duration = len
            }
            if (sourceName.includes("playerctl position")) {
                var sec = parseFloat(out)
                if (!isNaN(sec) && sec >= 0) mediaState.position = sec * 1000000
            }

            disconnectSource(sourceName)
        }

        function refresh() {
            connectSource("playerctl metadata --format '{{playerName}}|{{title}}|{{artist}}|{{album}}|{{mpris:artUrl}}|{{xesam:url}}'")
            connectSource("playerctl status")
            connectSource("playerctl metadata mpris:length")
            connectSource("playerctl position")
        }

        // Fetch immediately so data is ready before the popup is ever opened
        Component.onCompleted: refresh()
    }

    // Main poll — keeps state fresh every second in the background
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: mediaSource.refresh()
    }

    // Fallback position tick for players that don't expose position via MPRIS
    Timer {
        interval: 1000
        running: mediaState.isPlaying && !mediaState.hasPosition
        repeat: true
        onTriggered: {
            if (!mediaState.hasPosition)
                mediaState.position += 1000000
        }
    }

    // Thumbnail cache-buster — forces a re-fetch of the image every 30 seconds
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: mediaState.artRefreshTick++
    }

    // One-shot after a seek to re-sync position from playerctl
    Timer {
        id: seekRefresh
        interval: 200
        repeat: false
        onTriggered: mediaSource.refresh()
    }

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
                TopPanel{}

                // Second Row of Panels (Weather-time & Media Player)
                RowLayout {
                    spacing: 2
                    width: widgetMainWindow.cardWidth - 3
                    anchors.horizontalCenter: parent.horizontalCenter

                    //              Weather & Time
                    WeatherTimeCard {}

                    //              Media Player
                    MediaBar{
                        state: mediaState
                        onSeekRequested: seekRefresh.restart()
                    }
                }

                // DND, Mic button & Volume / Brightness
                RowLayout {
                    spacing: 2
                    width: widgetMainWindow.cardWidth - 3
                    anchors.horizontalCenter: parent.horizontalCenter

                    //  DnD
                    DndCard {}

                    //  Mic Mute
                    MicCard {}

                    //Volume & Brightness
                    VolumeBrightnessCard{}
                }

                //System Stats & Alarm
                RowLayout {
                    spacing: 2
                    width: widgetMainWindow.cardWidth - 3
                    anchors.horizontalCenter: parent.horizontalCenter

                    // System Information Tab
                    SystemInfoCard{
                        Layout.fillWidth: true
                    }

                    // Alarm
                    AlarmCard {}
                }

                // Bash terminal panel
                TerminalPanel{}
            }
        }
    }
}

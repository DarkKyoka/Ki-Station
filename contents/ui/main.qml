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

    Theme{
        id: appTheme
    }


    property int cardWidth: 430
    // One query avoids four process launches for every media refresh.
    readonly property string mediaQuery: "playerctl metadata --format '{{playerName}}|{{status}}|{{title}}|{{artist}}|{{album}}|{{mpris:artUrl}}|{{xesam:url}}|{{mpris:length}}|{{position}}'"

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
            var out = (data["stdout"] || "").trim()

            if (sourceName === widgetMainWindow.mediaQuery) {
                var parts = out.split("|")

                if (parts.length < 9 || parts[0] === "") {
                    mediaState.activePlayer = ""
                    mediaState.player       = ""
                    mediaState.title        = "Nothing Playing"
                    mediaState.artist       = ""
                    mediaState.album        = ""
                    mediaState.videoUrl     = ""
                    mediaState.artUrl       = ""
                    mediaState.isPlaying    = false
                    mediaState.position     = 0
                    mediaState.duration     = 0
                } else {
                    mediaState.activePlayer = parts[0]
                    mediaState.isPlaying    = parts[1] === "Playing"
                    mediaState.title        = parts[2] || "Nothing Playing"
                    mediaState.artist       = parts[3] || ""
                    mediaState.album        = parts[4] || ""
                    mediaState.player       = parts[0]
                    mediaState.videoUrl     = parts[6] || ""

                    var art      = parts[5] || ""
                    var pageUrl  = parts[6] || ""
                    var length   = parseFloat(parts[7])
                    var position = parseFloat(parts[8])

                    // Firefox sets artUrl to the watch page, so derive a thumbnail instead.
                    if (art.includes("youtube.com/watch") || art.includes("youtu.be/"))
                        art = ""
                    if (art === "" && pageUrl !== "")
                        art = mediaState.getThumbnail(pageUrl)

                    mediaState.artUrl = art
                    if (!isNaN(length) && length > 0)
                        mediaState.duration = length
                    if (!isNaN(position) && position >= 0)
                        mediaState.position = position
                }
            }

            disconnectSource(sourceName)
        }

        function refresh() {
            connectSource(widgetMainWindow.mediaQuery)
        }

        // Fetch immediately so data is ready before the popup is ever opened
        Component.onCompleted: refresh()
    }

    // Active playback stays responsive; paused or absent players need less polling.
    Timer {
        interval: mediaState.isPlaying ? 1000 : 5000
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

    // Thumbnail cache-buster, forces a re-fetch of the image every 30 seconds
    Timer {
        interval: 30000
        running: mediaState.artUrl !== ""
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
            color: appTheme.widgetBackgroundColor


            Column {
                y: 2
                spacing: 2
                anchors.horizontalCenter: parent.horizontalCenter
                id: mainColumn



                //      TOP PANEL
                TopPanel { theme: appTheme }

                // Second Row of Panels (Weather-time & Media Player)
                RowLayout {
                    spacing: 2
                    width: widgetMainWindow.cardWidth - 3
                    anchors.horizontalCenter: parent.horizontalCenter

                    //              Weather & Time
                    WeatherTimeCard { theme: appTheme }

                    //              Media Player
                    MediaBar{
                        theme: appTheme
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
                    DndCard { theme: appTheme }

                    //  Mic Mute
                    MicCard { theme: appTheme }

                    //Volume & Brightness
                    VolumeBrightnessCard { theme: appTheme }
                }

                //System Stats & Alarm
                RowLayout {
                    spacing: 2
                    width: widgetMainWindow.cardWidth - 3
                    anchors.horizontalCenter: parent.horizontalCenter

                    // System Information Tab
                    SystemInfoCard{
                        theme: appTheme
                        Layout.fillWidth: true
                    }

                    // Alarm
                    AlarmCard { theme: appTheme }
                }

                // Bash terminal panel
                TerminalPanel { theme: appTheme }
            }
        }
    }
}

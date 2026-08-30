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
    readonly property string mediaQuery: "playerctl -a metadata --format '{{playerInstance}}\t{{playerName}}\t{{status}}\t{{title}}\t{{artist}}\t{{album}}\t{{mpris:artUrl}}\t{{xesam:url}}\t{{mpris:length}}\t{{position}}'"

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: "utilities-system-monitor"

    compactRepresentation: PlasmaComponents3.ToolButton {
        id: compactButton
        display: PlasmaComponents3.ToolButton.IconOnly
        icon.name: "utilities-system-monitor"
        onClicked: widgetMainWindow.expanded = !widgetMainWindow.expanded
    }

    // Persistent media state
    // Lives at PlasmoidItem level so it survives popup open/close cycles.
    // fullRepresentation reads from here and shows data instantly on open.
    QtObject {
        id: mediaState

        // Keep the selected player as the command target while it is paused.
        property string activePlayer: ""
        property var    playerStatuses: ({})
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
        property bool   hasPosition:  false
        // Some MPRIS players briefly report 0 or the old timestamp after seeking.
        // Keep the requested position locally until their timestamp catches up.
        property bool   positionOverrideActive: false
        property double positionOverrideGraceUntil: 0
        property int    artRefreshTick: 0

        function getThumbnail(url) {
            var idx = url.indexOf("v=")
            if (idx === -1) return ""
            var id = url.substring(idx + 2)
            var amp = id.indexOf("&")
            if (amp !== -1) id = id.substring(0, amp)
            return id !== "" ? "https://img.youtube.com/vi/" + id + "/mqdefault.jpg" : ""
        }

        function bestCandidate(candidates) {
            var best = null
            var bestScore = -1

            for (var i = 0; i < candidates.length; i++) {
                var candidate = candidates[i]
                var score = 0
                if (!isNaN(parseFloat(candidate[8])) && parseFloat(candidate[8]) > 0)
                    score += 4
                if (candidate[6] !== "")
                    score += 2
                if (candidate[4] !== "")
                    score += 1

                if (score > bestScore) {
                    best = candidate
                    bestScore = score
                }
            }

            return best
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
                var records = out === "" ? [] : out.split("\n")
                var playingParts = []
                var newlyPlayingParts = []
                var selectedParts = null
                var nextStatuses = ({})

                for (var recordIndex = 0; recordIndex < records.length; recordIndex++) {
                    var record = records[recordIndex].trim()
                    if (record === "")
                        continue

                    var candidate = record.split("\t")
                    if (candidate.length < 10)
                        continue

                    var playerName = candidate[0]
                    var status = candidate[2]
                    nextStatuses[playerName] = status

                    if (playerName === mediaState.activePlayer)
                        selectedParts = candidate

                    if (status === "Playing") {
                        playingParts.push(candidate)
                        if (mediaState.playerStatuses[playerName] !== "Playing")
                            newlyPlayingParts.push(candidate)
                    }
                }

                if (newlyPlayingParts.length > 0) {
                    selectedParts = mediaState.bestCandidate(newlyPlayingParts)
                } else if (selectedParts !== null && selectedParts[2] !== "Stopped") {
                    if (selectedParts[2] !== "Playing" && playingParts.length > 0)
                        selectedParts = mediaState.bestCandidate(playingParts)
                } else if (playingParts.length > 0) {
                    selectedParts = mediaState.bestCandidate(playingParts)
                } else {
                    // An arbitrary paused player should not take over at startup.
                    selectedParts = null
                }

                mediaState.playerStatuses = nextStatuses

                if (selectedParts === null || selectedParts[0] === "") {
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
                    mediaState.hasPosition  = false
                    mediaState.positionOverrideActive = false
                    mediaState.positionOverrideGraceUntil = 0
                } else {
                    var nextPlayer = selectedParts[0]
                    var nextTitle = selectedParts[3] || "Nothing Playing"
                    var trackChanged = nextPlayer !== mediaState.activePlayer ||
                                       nextTitle !== mediaState.title

                    if (trackChanged)
                        mediaState.positionOverrideActive = false

                    mediaState.activePlayer = nextPlayer
                    mediaState.isPlaying    = selectedParts[2] === "Playing"
                    mediaState.title        = nextTitle
                    mediaState.artist       = selectedParts[4] || ""
                    mediaState.album        = selectedParts[5] || ""
                    mediaState.player       = selectedParts[1]
                    mediaState.videoUrl     = selectedParts[7] || ""

                    var art      = selectedParts[6] || ""
                    var pageUrl  = selectedParts[7] || ""
                    var length   = parseFloat(selectedParts[8])
                    var position = parseFloat(selectedParts[9])

                    // Firefox sets artUrl to the watch page, so derive a thumbnail instead.
                    if (art.includes("youtube.com/watch") || art.includes("youtu.be/"))
                        art = ""
                    if (art === "" && pageUrl !== "")
                        art = mediaState.getThumbnail(pageUrl)

                    mediaState.artUrl = art
                    if (!isNaN(length) && length > 0)
                        mediaState.duration = length
                    else if (trackChanged)
                        mediaState.duration = 0

                    if (!isNaN(position) && position >= 0) {
                        var gracePeriodEnded = Date.now() >= mediaState.positionOverrideGraceUntil
                        var positionCaughtUp = gracePeriodEnded &&
                            Math.abs(position - mediaState.position) <= 2500000

                        if (!mediaState.positionOverrideActive || positionCaughtUp) {
                            mediaState.position = position
                            mediaState.positionOverrideActive = false
                        }
                        mediaState.hasPosition = true
                    } else {
                        mediaState.hasPosition = false
                        if (trackChanged)
                            mediaState.position = 0
                    }
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

    // Fallback clock for players with missing or stale MPRIS positions.
    Timer {
        interval: 1000
        running: mediaState.isPlaying &&
                 (!mediaState.hasPosition || mediaState.positionOverrideActive)
        repeat: true
        onTriggered: {
            if (!mediaState.hasPosition || mediaState.positionOverrideActive) {
                var nextPosition = mediaState.position + 1000000
                mediaState.position = mediaState.duration > 0
                    ? Math.min(nextPosition, mediaState.duration)
                    : nextPosition
            }
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
        implicitHeight: backgroundRect.height
        Layout.minimumWidth: backgroundRect.width
        Layout.minimumHeight: backgroundRect.height
        Layout.preferredWidth: backgroundRect.width
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
                        onRefreshRequested: mediaSource.refresh()
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

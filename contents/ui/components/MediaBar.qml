import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasma5support as P5Support

// Media player card — album art, track info, progress bar, controls.
// Receives mediaState from main.qml via property binding.
// Fires seekRequested() so main.qml can restart the seek refresh timer.
Rectangle {
    id: root

    Layout.fillWidth: true
    height: 124
    color: theme.surface

    // Data in
    // The whole mediaState object is passed down from PlasmoidItem level.
    // All properties on it are live bindings — they update automatically.
    property var state: null
    property var theme

    // Convenience aliases so the UI below reads cleanly
    readonly property string title:          state ? state.title          : "Nothing Playing"
    readonly property string artist:         state ? state.artist         : ""
    readonly property string player:         state ? state.player         : ""
    readonly property string artUrl:         state ? state.artUrl         : ""
    readonly property int    artRefreshTick: state ? state.artRefreshTick : 0
    readonly property bool   isPlaying:      state ? state.isPlaying      : false
    readonly property real   position:       state ? state.position       : 0
    readonly property real   duration:       state ? state.duration       : 0
    readonly property string activePlayer:   state ? state.activePlayer   : ""

    // Event out
    // Emitted after a seek so main.qml can restart the seekRefresh timer
    signal seekRequested()

    // ── Command source ─────────────────────────────────────────────────────
    P5Support.DataSource {
        id: mediaCommandSource
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
    }

    // formats microseconds to m:ss
    function formatTime(us) {
        var s = Math.floor(us / 1000000)
        var m = Math.floor(s / 60)
        s = s % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // Reset position when track changes
    Connections {
        target: root.state
        function onTitleChanged() {
            if (root.state && !root.state.hasPosition)
                root.state.position = 0
        }
    }

    // UI
    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 20

        // Album art + song info
        Row {
            spacing: 4

            // Album art with rounded mask
            Item {
                id: albumArt
                width: 75
                height: 55

                Image {
                    id: albumArtImg
                    anchors.fill: parent
                    // ?_r=N cache-busts the URL every 30s so QML re-fetches it
                    source: root.artUrl !== ""
                        ? root.artUrl + "?_r=" + root.artRefreshTick
                        : ""
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

                // Fallback when no art is available
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: theme.surfaceAlt
                    visible: root.artUrl === "" || albumArtImg.status !== Image.Ready
                    z: -1
                }
            }

            // Track info
            Column {
                y: 3
                spacing: 1

                Text {
                    text: root.title
                    color: theme.text
                    font.pointSize: 10
                    width: 160
                    elide: Text.ElideRight
                }
                Text {
                    text: root.artist
                    color: theme.subtext
                    font.pointSize: 8
                    width: 160
                    elide: Text.ElideRight
                }
                Text {
                    text: root.player
                    color: theme.positive
                    font.pointSize: 8
                }
            }
        }

        // Progress bar + controls
        Column {
            width: parent.width
            spacing: 2

            // Time + controls row
            Row {
                width: parent.width

                // Current position
                Text {
                    text: formatTime(progressBar.pressed ? progressBar.value : root.position)
                    color: theme.text
                    font.pointSize: 8
                    width: 78
                    horizontalAlignment: Text.AlignLeft
                }

                // Playback controls
                Row {
                    spacing: 15
                    topPadding: 2

                    ThemedIcon {
                        source: "../icons/MediaPlayer/skip-back.svg"
                        width: 14; height: 14
                        color: theme.iconMedia
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mediaCommandSource.connectSource(
                                "playerctl -p " + root.activePlayer + " previous"
                            )
                        }
                    }

                    ThemedIcon {
                        source: root.isPlaying
                            ? "../icons/MediaPlayer/pause.svg"
                            : "../icons/MediaPlayer/play.svg"
                        width: 14; height: 14
                        color: theme.iconMedia
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mediaCommandSource.connectSource(
                                "playerctl -p " + root.activePlayer + " play-pause"
                            )
                        }
                    }

                    ThemedIcon {
                        source: "../icons/MediaPlayer/skip-forward.svg"
                        width: 14; height: 14
                        color: theme.iconMedia
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mediaCommandSource.connectSource(
                                "playerctl -p " + root.activePlayer + " next"
                            )
                        }
                    }
                }

                // Duration
                Text {
                    text: root.title === "Nothing Playing" ? "--:--" : formatTime(root.duration)
                    color: theme.text
                    font.pointSize: 8
                    width: 78
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Progress / seek slider
            Slider {
                id: progressBar
                width: parent.width
                height: 12
                from: 0
                to: root.duration

                // Only sync value from state when the user isn't dragging
                Binding {
                    target: progressBar
                    property: "value"
                    value: root.position
                    when: !progressBar.pressed
                }

                onPressedChanged: {
                    if (!pressed) {
                        // Write position back to state so the time label updates instantly
                        if (root.state) root.state.position = value

                        var seconds = value / 1000000
                        mediaCommandSource.connectSource(
                            "playerctl -p " + root.activePlayer + " position " + seconds
                        )

                        // Tell main.qml to restart seekRefresh timer
                        root.seekRequested()
                    }
                }

                background: Rectangle {
                    x: progressBar.leftPadding
                    y: progressBar.topPadding + progressBar.availableHeight / 2 - height / 2
                    width: progressBar.availableWidth
                    height: 12
                    radius: 8
                    color: theme.mediaProgressTrackColor

                    Rectangle {
                        width: progressBar.visualPosition * parent.width
                        height: parent.height
                        radius: 8
                        color: theme.positive
                    }
                }

                handle: Item { width: 0; height: 0 }
            }
        }
    }
}

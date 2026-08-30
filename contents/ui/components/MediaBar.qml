import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasma5support as P5Support

// Compact media card. Playback state is owned by main.qml so it survives
// opening and closing the widget.
Rectangle {
    id: root

    Layout.fillWidth: true
    height: 124
    color: theme.surface

    property var state: null
    property var theme

    readonly property string title:          state ? state.title          : "Nothing Playing"
    readonly property string artist:         state ? state.artist         : ""
    readonly property string album:          state ? state.album          : ""
    readonly property string player:         state ? state.player         : ""
    readonly property string artUrl:         state ? state.artUrl         : ""
    readonly property int    artRefreshTick: state ? state.artRefreshTick : 0
    readonly property bool   isPlaying:      state ? state.isPlaying      : false
    readonly property real   position:       state ? state.position       : 0
    readonly property real   duration:       state ? state.duration       : 0
    readonly property string activePlayer:   state ? state.activePlayer   : ""
    readonly property bool   hasPlayer:      activePlayer !== ""
    readonly property bool   canSeek:        hasPlayer && duration > 0

    signal seekRequested()
    signal refreshRequested()

    P5Support.DataSource {
        id: mediaCommandSource
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            root.refreshRequested()
        }
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'"
    }

    function runPlayerCommand(action) {
        if (!root.hasPlayer)
            return

        mediaCommandSource.connectSource(
            "playerctl -p " + root.shellQuote(root.activePlayer) + " " + action
        )
    }

    function formatTime(us) {
        if (!isFinite(us) || us < 0)
            return "--:--"

        var totalSeconds = Math.floor(us / 1000000)
        var hours = Math.floor(totalSeconds / 3600)
        var minutes = Math.floor((totalSeconds % 3600) / 60)
        var seconds = totalSeconds % 60
        var paddedSeconds = (seconds < 10 ? "0" : "") + seconds

        if (hours > 0)
            return hours + ":" + (minutes < 10 ? "0" : "") + minutes + ":" + paddedSeconds

        return minutes + ":" + paddedSeconds
    }

    function displayPlayerName(name) {
        if (name === "")
            return "No active player"

        var shortName = name.split(".")[0].replace(/[-_]/g, " ")
        if (shortName.toLowerCase() === "plasma browser integration")
            return "Browser"

        var words = shortName.split(" ")
        for (var i = 0; i < words.length; i++)
            words[i] = words[i].charAt(0).toUpperCase() + words[i].slice(1)
        return words.join(" ")
    }

    function trackDetails() {
        if (root.artist !== "" && root.album !== "")
            return root.artist + " - " + root.album
        if (root.artist !== "")
            return root.artist
        if (root.album !== "")
            return root.album
        return root.hasPlayer ? "Unknown artist" : "No active media session"
    }

    function artworkSource() {
        if (root.artUrl === "" || root.artUrl.indexOf("file:") === 0)
            return root.artUrl

        var separator = root.artUrl.indexOf("?") === -1 ? "?" : "&"
        return root.artUrl + separator + "_r=" + root.artRefreshTick
    }

    function commitSeek(value) {
        if (!root.canSeek)
            return

        if (root.state)
            root.state.position = value

        root.runPlayerCommand("position " + (value / 1000000))
        root.seekRequested()
    }

    component MediaButton: AbstractButton {
        id: mediaButton

        property url iconSource: ""
        property string tooltipText: ""

        implicitWidth: 28
        implicitHeight: 28
        hoverEnabled: true
        opacity: enabled ? 1 : 0.35

        ToolTip.visible: hovered && tooltipText !== ""
        ToolTip.text: tooltipText
        ToolTip.delay: 500

        background: Rectangle {
            radius: 4
            color: mediaButton.down
                ? theme.surfaceAlt
                : mediaButton.hovered ? theme.border : "transparent"
        }

        contentItem: Item {
            ThemedIcon {
                anchors.centerIn: parent
                width: 15
                height: 15
                source: mediaButton.iconSource
                color: theme.iconMedia
            }
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 8

        RowLayout {
            width: parent.width
            height: 54
            spacing: 8

            Item {
                id: albumArt
                Layout.preferredWidth: 54
                Layout.preferredHeight: 54

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: theme.surfaceAlt

                    ThemedIcon {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: root.isPlaying
                            ? "../icons/MediaPlayer/pause.svg"
                            : "../icons/MediaPlayer/play.svg"
                        color: theme.subtext
                        opacity: 0.7
                    }
                }

                Image {
                    id: albumArtImage
                    anchors.fill: parent
                    source: root.artworkSource()
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    visible: false
                }

                Rectangle {
                    id: albumArtMask
                    anchors.fill: parent
                    radius: 6
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: albumArtImage
                    maskSource: albumArtMask
                    visible: albumArtImage.status === Image.Ready
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: theme.text
                    font.pointSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.trackDetails()
                    color: theme.subtext
                    font.pointSize: 8
                    elide: Text.ElideRight
                }

                Item { Layout.fillHeight: true }

                Text {
                    Layout.fillWidth: true
                    text: root.displayPlayerName(root.player) + (root.hasPlayer
                        ? (root.isPlaying ? " - Playing" : " - Paused") : "")
                    color: root.hasPlayer ? theme.positive : theme.subtext
                    font.pointSize: 8
                    elide: Text.ElideRight
                }
            }
        }

        Column {
            width: parent.width
            spacing: 4

            RowLayout {
                width: parent.width
                // Give the 28px media buttons a little more vertical room so
                // the controls and timestamps sit lower in the card.
                height: 28
                spacing: 0

                // WeatherTimeCard's condition row is slightly lower; this
                // keeps the two cards visually aligned without moving the bar.
                transform: Translate { y: 4 }

                Text {
                    Layout.preferredWidth: 48
                    text: root.hasPlayer
                        ? root.formatTime(progressBar.pressed ? progressBar.value : root.position)
                        : "--:--"
                    color: theme.subtext
                    font.pointSize: 8
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Row {
                    spacing: 6

                    MediaButton {
                        iconSource: "../icons/MediaPlayer/skip-back.svg"
                        tooltipText: "Previous"
                        enabled: root.hasPlayer
                        onClicked: root.runPlayerCommand("previous")
                    }

                    MediaButton {
                        iconSource: root.isPlaying
                            ? "../icons/MediaPlayer/pause.svg"
                            : "../icons/MediaPlayer/play.svg"
                        tooltipText: root.isPlaying ? "Pause" : "Play"
                        enabled: root.hasPlayer
                        onClicked: root.runPlayerCommand("play-pause")
                    }

                    MediaButton {
                        iconSource: "../icons/MediaPlayer/skip-forward.svg"
                        tooltipText: "Next"
                        enabled: root.hasPlayer
                        onClicked: root.runPlayerCommand("next")
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    Layout.preferredWidth: 48
                    text: root.canSeek ? root.formatTime(root.duration) : "--:--"
                    color: theme.subtext
                    font.pointSize: 8
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Slider {
                id: progressBar

                width: parent.width
                height: 18
                from: 0
                to: Math.max(1, root.duration)
                enabled: root.canSeek
                hoverEnabled: true
                leftPadding: 0
                rightPadding: 0

                Binding {
                    target: progressBar
                    property: "value"
                    value: Math.min(root.position, progressBar.to)
                    when: !progressBar.pressed
                }

                onPressedChanged: {
                    if (!pressed)
                        root.commitSeek(value)
                }

                // Keyboard changes do not enter the pressed state.
                onMoved: {
                    if (!pressed)
                        root.commitSeek(value)
                }

                background: Rectangle {
                    x: progressBar.leftPadding
                    y: progressBar.topPadding + progressBar.availableHeight / 2 - height / 2
                    width: progressBar.availableWidth
                    height: 4
                    radius: 2
                    color: theme.mediaProgressTrackColor
                    opacity: progressBar.enabled ? 1 : 0.55

                    Rectangle {
                        width: progressBar.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: theme.positive
                    }
                }

                handle: Rectangle {
                    x: progressBar.leftPadding
                        + progressBar.visualPosition * (progressBar.availableWidth - width)
                    y: progressBar.topPadding
                        + progressBar.availableHeight / 2 - height / 2
                    width: progressBar.hovered || progressBar.pressed ? 12 : 8
                    height: width
                    radius: width / 2
                    color: theme.positive
                    border.width: 1
                    border.color: theme.text
                    visible: progressBar.enabled
                }
            }
        }
    }
}

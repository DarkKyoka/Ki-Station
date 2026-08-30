import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasma5support as P5Support


Rectangle {
    id: root

    color: theme.surface
    height: 130
    //width: 97
    Layout.preferredWidth: 97

    property bool isMuted: false
    property var theme


    P5Support.DataSource{
        id: micSource
        engine: "executable"
        connectedSources: []
        
        onNewData: (sourceName, data) => {
            root.isMuted = data["stdout"].trim().includes("yes")
            disconnectSource(sourceName)
        }
    }

    //checks for mic status once per 2 seconds
    Timer{
        interval: 2000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: micSource.connectSource("pactl get-source-mute @DEFAULT_SOURCE@")
    }

    // Fire-and-forget source for sending mute/unmute commands
    P5Support.DataSource {
        id: micCommandSource
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
    }

    // UI
    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        //icon handle
        ThemedIcon {
            source: root.isMuted ?  "../icons/Mic/mic-off.svg" : "../icons/Mic/mic-on.svg"
            width: 60
            height: 60
            color: root.isMuted ? theme.microphoneMutedIconColor : theme.microphoneEnabledIconColor
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        //state
        Text {
            text: root.isMuted ? "Mic: Disabled" : "Mic: Enabled"
            color: theme.text
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
            root.isMuted = !root.isMuted
            var cmd = root.isMuted
                ? "pactl set-source-mute @DEFAULT_SOURCE@ 1"
                : "pactl set-source-mute @DEFAULT_SOURCE@ 0"
            micCommandSource.connectSource(cmd)
        }
    }
}

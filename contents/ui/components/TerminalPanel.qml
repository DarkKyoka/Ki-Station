import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami


Rectangle {
    id: root

    width: widgetMainWindow.cardWidth
    height: 150
    color: theme.surface
    radius: 0

    property string promptUser: "User"
    property string promptHost: "ThisPC"
    property string currentPath: "~"
    property var outputLines: []
    property var theme

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
                root.promptUser = stdout
                disconnectSource(sourceName)
                return
            }
            if (sourceName === "hostname") {
                root.promptHost = stdout
                disconnectSource(sourceName)
                return
            }

            // Everything else goes to the output stream
            if (stdout.length > 0) {
                var lines = root.outputLines.slice()
                lines.push(stdout)
                root.outputLines = lines
            }
            if (stderr.length > 0) {
                var lines = root.outputLines.slice()
                lines.push("error: " + stderr)
                root.outputLines = lines
            }

            disconnectSource(sourceName)
        }

        Component.onCompleted: {
            connectSource("whoami")
            connectSource("hostname")
        }

    }

    // UI
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
                color: theme.subtext
                Layout.fillWidth: true
            }

            PlasmaComponents3.ToolButton {
                icon.name: "edit-clear-history"
                onClicked: {
                    root.outputLines = []
                }
            }
        }

        // Input line
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: root.promptUser + "@" + root.promptHost + ":" + root.currentPath + "$"
                color: theme.terminalPrompt
                font.family: "monospace"
                font.pixelSize: 10
            }

            PlasmaComponents3.TextField {
                id: commandInput
                Layout.fillWidth: true
                placeholderText: ""
                font.family: "monospace"
                font.pixelSize: 10
                color: theme.terminalText

                // Blend into the terminal — no border, no background
                background: Item {}

                onAccepted: {
                    var cmd = text.trim()
                    if (cmd.length === 0) return

                    var lines = root.outputLines.slice()
                    lines.push(root.promptUser + "@" + root.promptHost + ":~$ " + cmd)
                    root.outputLines = lines

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
            model: root.outputLines
            spacing: 0

            // No background — inherit parent card color
            Rectangle {
                anchors.fill: parent
                color: "transparent"
            }

            delegate: Text {
                width: outputView.width
                text: modelData
                color: theme.terminalText
                font.family: "monospace"
                font.pixelSize: 8
                wrapMode: Text.Wrap
            }

            // Auto-scroll to bottom whenever a new line is added
            onCountChanged: positionViewAtEnd()
        }


    }
}

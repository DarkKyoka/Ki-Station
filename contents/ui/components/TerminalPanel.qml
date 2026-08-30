import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Small shell console with bounded scrollback and a session-local working directory.
Rectangle {
    id: root

    width: widgetMainWindow.cardWidth
    height: 170
    color: theme.surface
    radius: 0

    property string currentPath: "~"
    property string shellCwd: ""
    property string commandStatus: "Ready"
    property bool commandRunning: false
    property bool followOutput: true
    property var outputLines: []
    property var commandHistory: []
    property int historyIndex: -1
    property var pendingCommands: ({})
    property int commandSerial: 0
    property string activeCommandSource: ""
    property var theme

    readonly property int maxScrollbackLines: 500
    // Only the current folder is shown once a prompt path gets long. The
    // shell still runs commands from the full absolute path in shellCwd.
    readonly property int promptPathMaxLength: 28
    readonly property string homeCommand: "printf '%s' \"$HOME\""
    // Keep the prompt focused on the working directory. The trailing marker
    // also leaves more room for the command input on narrow cards.
    readonly property string promptText: root.currentPath + " >"

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'"
    }

    function displayPath(path) {
        if (path === "" || path === "/")
            return path === "/" ? "/" : "~"

        // Keep the prompt compact while preserving the actual absolute cwd.
        var homePath = shellCwdHome
        var display = path
        if (homePath !== "" && (path === homePath || path.indexOf(homePath + "/") === 0))
            display = "~" + path.substring(homePath.length)

        if (display.length <= root.promptPathMaxLength)
            return display

        var slash = display.lastIndexOf("/")
        var leaf = slash >= 0 ? display.substring(slash + 1) : display
        return display.charAt(0) === "~" ? "~/.../" + leaf : "/.../" + leaf
    }

    property string shellCwdHome: ""

    function appendOutput(text, prefix) {
        if (text === undefined || text === null || String(text) === "")
            return

        var lines = String(text).replace(/\r/g, "").split("\n")
        var next = root.outputLines.slice()
        for (var i = 0; i < lines.length; i++)
            next.push((prefix || "") + lines[i])

        if (next.length > root.maxScrollbackLines)
            next = next.slice(next.length - root.maxScrollbackLines)
        root.outputLines = next
    }

    function rememberCommand(command) {
        var next = root.commandHistory.slice()
        if (next.length === 0 || next[next.length - 1] !== command)
            next.push(command)
        if (next.length > 50)
            next = next.slice(next.length - 50)
        root.commandHistory = next
        root.historyIndex = next.length
    }

    function browseHistory(direction) {
        if (root.commandHistory.length === 0)
            return ""

        var nextIndex = root.historyIndex + direction
        if (nextIndex < 0)
            nextIndex = 0
        if (nextIndex > root.commandHistory.length)
            nextIndex = root.commandHistory.length
        root.historyIndex = nextIndex
        return nextIndex === root.commandHistory.length ? "" : root.commandHistory[nextIndex]
    }

    function commandFor(command) {
        var cwdCommand = root.shellCwd === ""
            ? "cd -- \"$HOME\""
            : "cd -- " + root.shellQuote(root.shellCwd)

        // The markers let us retain cd state without keeping a process alive.
        var script = cwdCommand + " && " + command
            + "\nstatus=$?\nprintf '\\n__KISTATION_CWD__%s\\n__KISTATION_EXIT__%s\\n' \"$PWD\" \"$status\""
        return "bash -lc " + root.shellQuote(script)
    }

    function clearOutput() {
        root.outputLines = []
        root.followOutput = true
    }

    function cancelCommand() {
        if (!root.commandRunning || root.activeCommandSource === "")
            return

        promptSource.disconnectSource(root.activeCommandSource)
        root.appendOutput("^C", "error: ")
        root.commandRunning = false
        root.commandStatus = "Stopped"
        root.activeCommandSource = ""
    }

    function submitCommand(command) {
        var cmd = String(command || "").trim()
        if (cmd === "")
            return
        if (root.commandRunning) {
            root.appendOutput("A command is still running.", "error: ")
            return
        }

        root.rememberCommand(cmd)
        root.appendOutput(root.promptText + " " + cmd, "")

        var sourceName = root.commandFor(cmd) + " #" + (++root.commandSerial)
        var pending = root.pendingCommands
        pending[sourceName] = { command: cmd }
        root.pendingCommands = pending
        root.commandRunning = true
        root.commandStatus = "Running"
        root.activeCommandSource = sourceName
        promptSource.connectSource(sourceName)
    }

    function handleCommandResult(sourceName, data) {
        if (sourceName !== root.activeCommandSource)
            return

        var stdout = String((data && data["stdout"]) || "").replace(/\r/g, "")
        var stderr = String((data && data["stderr"]) || "").replace(/\r/g, "")
        var cwdMarker = "__KISTATION_CWD__"
        var exitMarker = "__KISTATION_EXIT__"
        var cwdIndex = stdout.lastIndexOf(cwdMarker)
        var exitIndex = stdout.lastIndexOf(exitMarker)
        var exitCode = 0

        if (cwdIndex >= 0) {
            var cwdStart = cwdIndex + cwdMarker.length
            var cwdEnd = exitIndex > cwdStart ? exitIndex : stdout.length
            var discoveredCwd = stdout.substring(cwdStart, cwdEnd).trim()
            if (discoveredCwd !== "") {
                root.shellCwd = discoveredCwd
                root.currentPath = root.displayPath(discoveredCwd)
            }

            if (exitIndex >= 0) {
                var exitText = stdout.substring(exitIndex + exitMarker.length).trim()
                var parsedExit = parseInt(exitText.split("\n")[0])
                if (!isNaN(parsedExit))
                    exitCode = parsedExit
            }
            stdout = stdout.substring(0, cwdIndex)
        }

        root.appendOutput(stdout, "")
        root.appendOutput(stderr, "error: ")
        root.commandStatus = exitCode === 0 ? "Ready" : "Exit " + exitCode
        root.commandRunning = false
        root.activeCommandSource = ""

        var pending = root.pendingCommands
        delete pending[sourceName]
        root.pendingCommands = pending
    }

    P5Support.DataSource {
        id: promptSource
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (sourceName === "pwd") {
                var initialPath = String((data && data["stdout"]) || "").trim()
                if (initialPath !== "") {
                    root.shellCwd = initialPath
                    root.currentPath = root.displayPath(initialPath)
                }
            } else if (sourceName === root.homeCommand) {
                var homePath = String((data && data["stdout"]) || "").trim()
                if (homePath !== "") {
                    root.shellCwdHome = homePath
                    if (root.shellCwd !== "")
                        root.currentPath = root.displayPath(root.shellCwd)
                }
            } else {
                root.handleCommandResult(sourceName, data)
            }

            disconnectSource(sourceName)
        }

        Component.onCompleted: {
            connectSource("pwd")
            connectSource(root.homeCommand)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22

            PlasmaComponents3.Label {
                text: "Bash"
                font.pixelSize: Kirigami.Units.gridUnit * 0.7
                color: theme.terminalHeaderTextColor
                Layout.fillWidth: true
            }

            PlasmaComponents3.Label {
                text: root.commandStatus
                color: root.commandStatus === "Ready" ? theme.subtext : theme.terminalHeaderTextColor
                font.family: "monospace"
                font.pixelSize: 8
            }

            PlasmaComponents3.ToolButton {
                icon.name: "process-stop"
                visible: root.commandRunning
                Accessible.name: "Stop running command"
                ToolTip.text: "Stop running command"
                ToolTip.visible: hovered
                onClicked: root.cancelCommand()
            }

            PlasmaComponents3.ToolButton {
                icon.name: "edit-clear-history"
                enabled: root.outputLines.length > 0
                Accessible.name: "Clear terminal output"
                ToolTip.text: "Clear terminal output"
                ToolTip.visible: hovered
                onClicked: root.clearOutput()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            PlasmaComponents3.Label {
                text: root.promptText
                color: theme.terminalPrompt
                font.family: "monospace"
                font.pixelSize: 10
            }

            PlasmaComponents3.TextField {
                id: commandInput
                Layout.fillWidth: true
                enabled: !root.commandRunning
                placeholderText: ""
                font.family: "monospace"
                font.pixelSize: 10
                color: theme.terminalText
                selectByMouse: true
                background: Item {}

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Up) {
                        text = root.browseHistory(-1)
                        cursorPosition = text.length
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        text = root.browseHistory(1)
                        cursorPosition = text.length
                        event.accepted = true
                    } else if (event.key === Qt.Key_L && (event.modifiers & Qt.ControlModifier)) {
                        root.clearOutput()
                        event.accepted = true
                    }
                }

                onAccepted: {
                    root.submitCommand(text)
                    text = ""
                }
            }
        }

        ListView {
            id: outputView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.outputLines
            spacing: 0
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: Text {
                width: outputView.width
                text: modelData
                color: modelData.indexOf("error: ") === 0 ? theme.negative : theme.terminalText
                font.family: "monospace"
                font.pixelSize: 8
                wrapMode: Text.WrapAnywhere
            }

            onMovementEnded: root.followOutput = atYEnd

            onCountChanged: {
                if (root.followOutput)
                    Qt.callLater(positionViewAtEnd)
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    Layout.fillWidth: true
    implicitHeight: 124
    color: theme.surface

    // State
    property string alarmLabel:       "Quick Alarm"
    property bool   alarmRunning:     false
    property bool   alarmFired:       false
    property bool   isEditing:        false   // switches between the two inner views
    property var    theme

    // Time the user last confirmed — never touched by the countdown
    property int    setTotalSeconds:  300
    // Live value the countdown decrements
    property int    remainingSeconds: 300

    // Auto-formats HH:MM:SS from remainingSeconds
    property string alarmTime: {
        var h = Math.floor(remainingSeconds / 3600)
        var m = Math.floor((remainingSeconds % 3600) / 60)
        var s = remainingSeconds % 60
        return (h < 10 ? "0" + h : h) + ":"
            + (m < 10 ? "0" + m : m) + ":"
            + (s < 10 ? "0" + s : s)
    }

    // Fire-and-forget source for the alarm notification command
    P5Support.DataSource {
        id: alarmCommandSource
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
    }


    // Countdown timer
    Timer {
        interval: 1000
        running: root.alarmRunning
        repeat: true
        onTriggered: {
            if (root.remainingSeconds > 0) {
                root.remainingSeconds -= 1
            } else {
                root.alarmRunning = false
                root.alarmFired   = true
                alarmCommandSource.connectSource(
                    "notify-send 'Ki Station' '" + root.alarmLabel + "' --icon=alarm-symbolic"
                )
            }
        }
    }

    // Blink timer, toggles a bool the time label reads its opacity from
    Timer {
        id: blinkTimer
        property bool blinkOn: false
        interval: 500
        running: root.alarmFired
        repeat: true
        onTriggered: blinkOn = !blinkOn
        onRunningChanged: if (!running) blinkOn = false
    }

    // Alarm view
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing
        visible: !root.isEditing

        // Header: label + edit button
        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents3.Label {
                text: root.alarmLabel
                font.pixelSize: Kirigami.Units.gridUnit * 0.7
                color: theme.subtext
                Layout.fillWidth: true
            }

            PlasmaComponents3.ToolButton {
                icon.name: "document-edit"
                onClicked: root.isEditing = true
            }
        }

        // Countdown display
        PlasmaComponents3.Label {
            text: root.alarmTime
            font.pixelSize: Kirigami.Units.gridUnit * 1.6
            font.bold: true
            color: root.alarmFired ? theme.negative : theme.terminalText
            opacity: blinkTimer.blinkOn ? 0.2 : 1.0
            Layout.alignment: Qt.AlignHCenter
        }

        // Reset , play and Pause buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing

            PlasmaComponents3.ToolButton {
                Layout.fillWidth: true
                icon.name: "dialog-close"
                icon.color: theme.negative
                onClicked: {
                    root.alarmRunning     = false
                    root.alarmFired       = false
                    root.remainingSeconds = root.setTotalSeconds
                }
            }

            PlasmaComponents3.ToolButton {
                Layout.fillWidth: true
                icon.name: root.alarmRunning ? "media-playback-pause" : "media-playback-start"
                
                enabled: root.remainingSeconds > 0 || root.alarmRunning
                onClicked: {
                    if (root.alarmFired) {
                        // Dismiss fired alarm and reset
                        root.alarmFired       = false
                        root.remainingSeconds = root.setTotalSeconds
                        return
                    }
                    root.alarmRunning = !root.alarmRunning
                }
            }
        }
    }

    // Edit timer view
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing
        visible: root.isEditing

        // Sync spinbox values to the current set time every time this view opens.
        // SpinBox value bindings break on first user interaction, so we do this
        // imperatively to ensure the values are always fresh on re-open.
        onVisibleChanged: {
            if (visible) {
                hourSpin.value   = Math.floor(root.setTotalSeconds / 3600)
                minuteSpin.value = Math.floor((root.setTotalSeconds % 3600) / 60)
                secondSpin.value = root.setTotalSeconds % 60
            }
        }

        // Header: title + back button
        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents3.Label {
                text: "Set countdown"
                font.pixelSize: Kirigami.Units.gridUnit * 0.7
                color: theme.subtext
                Layout.fillWidth: true
            }

            PlasmaComponents3.ToolButton {
                icon.name: "arrow-left"
                onClicked: root.isEditing = false
            }
        }

        // Time pickers
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            // hours
            SpinBox { id: hourSpin;   Layout.fillWidth: true; from: 0; to: 23; value: 0 }
            PlasmaComponents3.Label { text: "h"; color: theme.subtext; font.pixelSize: 11 }

            //minutes
            SpinBox { id: minuteSpin; Layout.fillWidth: true; from: 0; to: 59; value: 5 }
            PlasmaComponents3.Label { text: "m"; color: theme.subtext; font.pixelSize: 11 }

            //seconds
            SpinBox { id: secondSpin; Layout.fillWidth: true; from: 0; to: 59; value: 0 }
            PlasmaComponents3.Label { text: "s"; color: theme.subtext; font.pixelSize: 11 }
        }

        // Confirm button
        PlasmaComponents3.Button {
            text: "Set"
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                var total = hourSpin.value * 3600
                    + minuteSpin.value * 60
                    + secondSpin.value
                if (total > 0) {
                    root.setTotalSeconds  = total
                    root.remainingSeconds = total
                    root.alarmRunning     = false
                    root.alarmFired       = false
                }
                root.isEditing = false
            }
        }
    }
}

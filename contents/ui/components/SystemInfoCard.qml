import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasma5support as P5Support


Rectangle {
    id: root

    property real cpuUsage:      0.0
    property real ramUsedGib:    0.0
    property int  ramTotalGib:   0
    property real uploadSpeed:   0
    property real downloadSpeed: 0
    property var  _cpuPrev:      null
    property var  _netPrev:      null
    property var  theme

    // One read avoids three process launches for each statistics refresh.
    readonly property string statsQuery: "cat /proc/stat /proc/meminfo /proc/net/dev"

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024)       return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1048576)    return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        if (bytesPerSec < 1073741824) return (bytesPerSec / 1048576).toFixed(1) + " MB/s"
        return (bytesPerSec / 1073741824).toFixed(2) + " GB/s"
    }

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    implicitHeight: 124
    color: theme.surface
    clip: true

    P5Support.DataSource {
        id: sysStatsSource
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            var out = (data["stdout"] || "").trim()

            if (sourceName === root.statsQuery) {
                var lines = out.split("\n")
                var cpuLine = ""
                var memTotal = 0
                var memAvail = 0
                var totalRx = 0
                var totalTx = 0

                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()

                    if (line.indexOf("cpu ") === 0) {
                        cpuLine = line
                        continue
                    }

                    if (line.indexOf("MemTotal:") === 0) {
                        memTotal = parseInt(line.split(/\s+/)[1]) || 0
                        continue
                    }

                    if (line.indexOf("MemAvailable:") === 0) {
                        memAvail = parseInt(line.split(/\s+/)[1]) || 0
                        continue
                    }

                    var colon = line.indexOf(":")
                    if (colon !== -1) {
                        var device = line.substring(0, colon).trim()
                        var fields = line.substring(colon + 1).trim().split(/\s+/)
                        if (device !== "lo" && fields.length >= 9) {
                            totalRx += parseInt(fields[0]) || 0
                            totalTx += parseInt(fields[8]) || 0
                        }
                    }
                }

                if (cpuLine !== "") {
                    var tok     = cpuLine.split(/\s+/)
                    var user    = parseInt(tok[1]) || 0
                    var nice    = parseInt(tok[2]) || 0
                    var sys     = parseInt(tok[3]) || 0
                    var idle    = parseInt(tok[4]) || 0
                    var iowt    = parseInt(tok[5]) || 0
                    var irq     = parseInt(tok[6]) || 0
                    var sirq    = parseInt(tok[7]) || 0
                    var total   = user + nice + sys + idle + iowt + irq + sirq
                    var idleSum = idle + iowt

                    if (root._cpuPrev !== null) {
                        var dTotal = total   - root._cpuPrev.total
                        var dIdle  = idleSum - root._cpuPrev.idle
                        if (dTotal > 0)
                            root.cpuUsage = (dTotal - dIdle) / dTotal
                    }
                    root._cpuPrev = { total: total, idle: idleSum }
                }

                if (memTotal > 0) {
                    root.ramUsedGib  = (memTotal - memAvail) / 1048576
                    root.ramTotalGib = Math.round(memTotal / 1048576)
                }

                var now = Date.now()
                if (root._netPrev !== null) {
                    var dt = (now - root._netPrev.time) / 1000
                    if (dt > 0) {
                        root.downloadSpeed = Math.max(0, (totalRx - root._netPrev.rx) / dt)
                        root.uploadSpeed   = Math.max(0, (totalTx - root._netPrev.tx) / dt)
                    }
                }
                root._netPrev = { rx: totalRx, tx: totalTx, time: now }
            }

            disconnectSource(sourceName)
        }

        function refresh() {
            connectSource(root.statsQuery)
        }
    }

    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: sysStatsSource.refresh()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // CPU
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            ThemedIcon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; source: "../icons/SystemInfo/cpu.svg"; color: theme.cpuIconColor }
            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "CPU usage:"
                color: theme.text
                font.pixelSize: 13
                elide: Text.ElideRight
            }
            Text {
                Layout.preferredWidth: 42
                Layout.minimumWidth: 36
                text: Math.round(root.cpuUsage * 100) + "%"
                horizontalAlignment: Text.AlignRight
                color:  if(Math.round(root.cpuUsage * 100) >= 80){
                    theme.negative
                }else{
                    theme.text
                }
                font.pixelSize: 13
            }
        }

        // RAM
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            ThemedIcon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; source: "../icons/SystemInfo/memory-stick.svg"; color: theme.memoryIconColor }
            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "RAM usage:"
                color: theme.text
                font.pixelSize: 13
                elide: Text.ElideRight
            }
            Text {
                Layout.preferredWidth: Math.min(implicitWidth, 105)
                Layout.minimumWidth: 68
                Layout.maximumWidth: 105
                text: root.ramUsedGib.toFixed(1) + " / " + root.ramTotalGib + " GiB"
                color: theme.text
                font.pixelSize: 13
                minimumPixelSize: 10
                fontSizeMode: Text.HorizontalFit
                horizontalAlignment: Text.AlignRight
            }
        }

        // Network
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 5
                ThemedIcon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; source: "../icons/SystemInfo/ethernet-port.svg"; color: theme.ethernetIconColor }
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: "Network Stats"
                    color: theme.text
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.leftMargin: 23
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 4
                    Text { text: "↑"; color: theme.info; font.pixelSize: 13 }
                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: root.formatSpeed(root.uploadSpeed)
                        color: theme.info
                        font.pixelSize: 13
                        minimumPixelSize: 10
                        fontSizeMode: Text.HorizontalFit
                        elide: Text.ElideRight
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 4
                    Text { text: "↓"; color: theme.info; font.pixelSize: 13 }
                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: root.formatSpeed(root.downloadSpeed)
                        color: theme.info
                        font.pixelSize: 13
                        minimumPixelSize: 10
                        fontSizeMode: Text.HorizontalFit
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}

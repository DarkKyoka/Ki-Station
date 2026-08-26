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

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024)       return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1048576)    return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        if (bytesPerSec < 1073741824) return (bytesPerSec / 1048576).toFixed(1) + " MB/s"
        return (bytesPerSec / 1073741824).toFixed(2) + " GB/s"
    }

    Layout.fillWidth: true
    implicitHeight: 124
    color: "#2E0015"

    P5Support.DataSource {
        id: sysStatsSource
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            var out = data["stdout"].trim()

            if (sourceName === "cat /proc/stat") {
                var tok     = out.split("\n")[0].split(/\s+/)
                var user    = parseInt(tok[1]), nice = parseInt(tok[2])
                var sys     = parseInt(tok[3]), idle = parseInt(tok[4])
                var iowt    = parseInt(tok[5]), irq  = parseInt(tok[6])
                var sirq    = parseInt(tok[7])
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

            if (sourceName === "cat /proc/meminfo") {
                var memTotal = 0, memAvail = 0
                out.split("\n").forEach(function(line) {
                    if (line.startsWith("MemTotal:"))
                        memTotal = parseInt(line.split(/\s+/)[1])
                    if (line.startsWith("MemAvailable:"))
                        memAvail = parseInt(line.split(/\s+/)[1])
                })
                if (memTotal > 0) {
                    root.ramUsedGib  = (memTotal - memAvail) / 1048576
                    root.ramTotalGib = Math.round(memTotal / 1048576)
                }
            }

            if (sourceName === "cat /proc/net/dev") {
                var now = Date.now()
                var totalRx = 0, totalTx = 0
                var lines = out.split("\n")
                for (var i = 2; i < lines.length; i++) {
                    var parts = lines[i].trim().split(/\s+/)
                    if (parts.length < 10 || parts[0] === "lo:") continue
                    totalRx += parseInt(parts[1])
                    totalTx += parseInt(parts[9])
                }
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
            connectSource("cat /proc/stat")
            connectSource("cat /proc/meminfo")
            connectSource("cat /proc/net/dev")
        }
    }

    Timer {
        interval: 2000
        running: true
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
            Image { Layout.preferredWidth: 18; Layout.preferredHeight: 18; source: "../icons/SystemInfo/cpu.svg" }
            Text { text: "CPU usage:";
                color: "white";
                font.pixelSize: 13
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(root.cpuUsage * 100) + "%";
                color:  if(Math.round(root.cpuUsage * 100) >= 80){
                    "#FF6E6E"
                }else{
                    "white"
                }
                font.pixelSize: 13
            }
        }

        // RAM
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            Image { Layout.preferredWidth: 18; Layout.preferredHeight: 18; source: "../icons/SystemInfo/memory-stick.svg" }
            Text { text: "Ram usage:"; color: "white"; font.pixelSize: 13 }
            Item { Layout.fillWidth: true }
            Text { text: root.ramUsedGib.toFixed(1) + " / " + root.ramTotalGib + " GiB"; color: "white"; font.pixelSize: 13 }
        }

        // Network
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                spacing: 5
                Image { Layout.preferredWidth: 18; Layout.preferredHeight: 18; source: "../icons/SystemInfo/ethernet-port.svg" }
                Text { text: "Network Stats"; color: "white"; font.pixelSize: 13 }
            }

            RowLayout {
                Layout.leftMargin: 35
                spacing: 16
                RowLayout {
                    spacing: 4
                    Text { text: "↑"; color: "#5ac8fa"; font.pixelSize: 13 }
                    Text { text: root.formatSpeed(root.uploadSpeed); color: "#5ac8fa"; font.pixelSize: 13 }
                }
                RowLayout {
                    spacing: 4
                    Text { text: "↓"; color: "#5ac8fa"; font.pixelSize: 13 }
                    Text { text: root.formatSpeed(root.downloadSpeed); color: "#5ac8fa"; font.pixelSize: 13 }
                }
            }
        }
    }
}
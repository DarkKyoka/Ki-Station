import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.notificationmanager as NotificationManager


Rectangle {
    id: root

    color: "#2E0015"
    height: 130
    width: 97
    Layout.preferredWidth: 97

    property bool dndActive: false


    NotificationManager.Settings{
        id: notifSettings
    }

    // Refresh state every 0.5 seconds
    Timer{
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.dndActive = notifSettings.notificationsInhibitedUntil > new Date()
    }



    // UI
    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Image {
            source: root.dndActive ? "../icons/DnD/bell-off.svg" : "../icons/DnD/bell.svg"
            width: 60; height: 60
            sourceSize: Qt.size(width, height)
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Text {
            text: root.dndActive ? "DnD: On" : "DnD: Off"
            color: "white"
            font.pointSize: 8
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -35
        }
    }

    // The interaction logic of the panel
    MouseArea {

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            console.log("DnD clicked, current state:", root.dndActive)
            if (notifSettings.notificationsInhibitedUntil > new Date()) {
                notifSettings.notificationsInhibitedUntil = new Date(0)
            } else {
                var future = new Date()
                future.setFullYear(future.getFullYear() + 10)
                notifSettings.notificationsInhibitedUntil = future
            }
            notifSettings.save()    // saves to config
        }
    }
}
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.notificationmanager as NotificationManager


Rectangle {
    id: root

    color: theme.surface
    height: 130
    width: 97
    Layout.preferredWidth: 97

    property bool dndActive: false
    property var theme


    NotificationManager.Settings{
        id: notifSettings
    }

    // DND changes are infrequent, so a one-second check is sufficient.
    Timer{
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.dndActive = notifSettings.notificationsInhibitedUntil > new Date()
    }



    // UI
    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        ThemedIcon {
            source: root.dndActive ? "../icons/DnD/bell-off.svg" : "../icons/DnD/bell.svg"
            width: 60; height: 60
            color: root.dndActive ? theme.doNotDisturbOnIconColor : theme.doNotDisturbOffIconColor
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Text {
            text: root.dndActive ? "DnD: On" : "DnD: Off"
            color: theme.text
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

import QtQuick
import Qt5Compat.GraphicalEffects

// Recolours the project's fixed-colour SVG icons for every palette.
Item {
    id: root

    property url source: ""
    property color color: "white"
    property bool smooth: true

    Image {
        id: sourceImage
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(root.width, root.height)
        fillMode: Image.PreserveAspectFit
        smooth: root.smooth
        visible: false
    }

    ColorOverlay {
        anchors.fill: sourceImage
        source: sourceImage
        color: root.color
    }
}

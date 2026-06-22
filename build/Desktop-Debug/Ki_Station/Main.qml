import QtQuick

Window {
    width: 430
    height: 650
    visible: true

    color: "#470020"
    //opacity: 0.75

    title: qsTr("Hello World")

    Column{
        anchors.fill: parent

        Row{
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            Rectangle{
                width: 426
                height: 118
                radius: 10

                bottomLeftRadius: 0
                bottomRightRadius: 0

                color: "#2E0015"

                Row{
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4


                    //pfp
                    Rectangle{

                        anchors.verticalCenter: parent.verticalCenter



                        width: 88
                        height: 88
                        radius: width / 2
                        color: "#333333"


                    }

                    //Flavory wellcome
                    Text {
                        id: userFlavor
                        text: qsTr("Hey, User!")
                        font.pointSize: 16
                        color: "white"


                        anchors.verticalCenter: parent.verticalCenter
                    }


                    // Battery & Icon
                    Row{
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.left

                        Text {
                            id: batteryText
                            text: "100" + "%"
                            color: "white"
                            font.pointSize: 12
                        }

                    }
                    Column{



                        // Settings gear, Wifi, Mic status
                        Row{

                        }

                    }


                }


            }
        }





    }
}

import QtQuick 2.15
import QtQuick.Layouts 1.15
import quickshell.io 1.0 // QuickShell process execution

Rectangle {
    id: root
    width: 320
    height: 480
    color: "#1e1e2e" // Catppuccin mocha base
    radius: 12
    
    // Add border to stand out
    border.color: "#313244"
    border.width: 1

    property string externalIp: "Fetching..."
    property string statusText: "Ready"

    // Process helper to execute the python script
    Process {
        id: upnpProcess
        property var pendingCallback: null
        
        onStdoutData: (data) => {
            if (pendingCallback) {
                try {
                    let result = JSON.parse(data);
                    pendingCallback(result);
                } catch (e) {
                    // console.log("Failed to parse JSON:", data);
                }
            }
        }
    }

    function execHelper(args, callback) {
        upnpProcess.pendingCallback = callback;
        upnpProcess.command = ["python3", "/home/azterisk/projects/azterisk.host/scripts/upnp_helper.py"].concat(args);
        upnpProcess.running = true;
    }

    Component.onCompleted: {
        execHelper(["status"], function(res) {
            if (res.success && res.external_ip) {
                root.externalIp = res.external_ip;
            } else {
                root.externalIp = "Unknown / No UPnP";
            }
        });
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "azterisk.host"
            color: "#cdd6f4" // Text color
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "External IP: " + root.externalIp
            color: "#a6adc8"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: root.statusText
            color: "#f38ba8" // Red/pink status color
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            
            model: ListModel {
                ListElement { name: "Counter-Strike 2"; port: 27015; protocol: "tcp" }
                ListElement { name: "Counter-Strike 2 (UDP)"; port: 27015; protocol: "udp" }
                ListElement { name: "Minecraft Java"; port: 25565; protocol: "tcp" }
                ListElement { name: "Minecraft Bedrock"; port: 19132; protocol: "udp" }
                ListElement { name: "Palworld"; port: 8211; protocol: "udp" }
                ListElement { name: "Valheim"; port: 2456; protocol: "udp" }
                ListElement { name: "Terraria"; port: 7777; protocol: "tcp" }
                ListElement { name: "Rust"; port: 28015; protocol: "udp" }
                ListElement { name: "Enshrouded"; port: 15636; protocol: "udp" }
                ListElement { name: "HTTP Server"; port: 80; protocol: "tcp" }
            }

            delegate: Rectangle {
                width: ListView.view.width
                height: 56
                color: "#313244" // Surface0
                radius: 8

                property bool isActive: false

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: model.name
                            color: "#cdd6f4"
                            font.bold: true
                            font.pixelSize: 14
                        }
                        Text {
                            text: model.port + " / " + model.protocol.toUpperCase()
                            color: "#a6adc8"
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        width: 60
                        height: 30
                        radius: 6
                        color: parent.parent.isActive ? "#f38ba8" : "#89b4fa" // Stop is Red, Host is Blue
                        
                        Text {
                            anchors.centerIn: parent
                            text: parent.parent.parent.isActive ? "Stop" : "Host"
                            color: "#1e1e2e"
                            font.bold: true
                            font.pixelSize: 13
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let rect = parent.parent.parent;
                                if (rect.isActive) {
                                    root.statusText = "Stopping " + model.name + "...";
                                    root.execHelper(["remove", model.port.toString(), model.protocol], function(res) {
                                        if (res.success) {
                                            rect.isActive = false;
                                            root.statusText = model.name + " stopped.";
                                        } else {
                                            root.statusText = "Error stopping: " + (res.error || "");
                                        }
                                    });
                                } else {
                                    root.statusText = "Starting " + model.name + "...";
                                    root.execHelper(["add", model.port.toString(), model.protocol], function(res) {
                                        if (res.success) {
                                            rect.isActive = true;
                                            root.statusText = model.name + " is live!";
                                            if (res.ip) root.externalIp = res.ip;
                                        } else {
                                            root.statusText = "Error starting: " + (res.error || "");
                                        }
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

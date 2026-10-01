import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
    id: root
    moduleName: "azterisk.host"
    ipcTarget: "azterisk.host"
    manageIpc: false

    property var anchorItem: null
    property var hostWidget: null
    property var bar: null

    contentWidth: 350
    contentHeight: 500

    property string externalIp: "Fetching..."
    property string statusText: "Ready"
    property var itemsModel: []

    Process {
        id: upnpProcess
        property var pendingCallback: null
        
        onStdoutData: (data) => {
            if (pendingCallback) {
                try {
                    let result = JSON.parse(data);
                    pendingCallback(result);
                } catch (e) {}
            }
        }
    }

    function execHelper(args, callback) {
        upnpProcess.pendingCallback = callback;
        let scriptPath = Qt.resolvedUrl("scripts/upnp_helper.py").replace("file://", "");
        upnpProcess.command = ["python3", scriptPath].concat(args);
        upnpProcess.running = true;
    }

    function refresh() {
        execHelper(["status"], function(res) {
            if (res.success) {
                if (res.external_ip) root.externalIp = res.external_ip;
                root.itemsModel = res.items || [];
            }
        });
    }

    Component.onCompleted: refresh()
    onOpenedChanged: if (opened) refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "azterisk.host"
            color: "#cdd6f4"
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
            color: "#f38ba8"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            
            model: root.itemsModel

            delegate: Rectangle {
                width: ListView.view.width
                height: 64
                color: "#313244"
                radius: 8

                property bool portActive: false
                property bool appActive: modelData.app_running === true

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: modelData.name
                            color: "#cdd6f4"
                            font.bold: true
                            font.pixelSize: 14
                        }
                        Text {
                            text: modelData.port + " / " + modelData.protocol.toUpperCase() + (modelData.manager !== 'none' ? " (" + modelData.manager + ")" : "")
                            color: "#a6adc8"
                            font.pixelSize: 12
                        }
                    }

                    // App control button
                    Rectangle {
                        visible: modelData.manager !== 'none'
                        width: 50
                        height: 30
                        radius: 6
                        color: appActive ? "#a6e3a1" : "#f38ba8" // Green running, Red stopped
                        Text { anchors.centerIn: parent; text: "App"; color: "#1e1e2e"; font.bold: true; font.pixelSize: 13 }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let action = appActive ? "stop" : "start";
                                root.statusText = (appActive ? "Stopping " : "Starting ") + modelData.name + "...";
                                root.execHelper(["app", action, modelData.manager, modelData.target], function(res) {
                                    if (res.success) {
                                        root.statusText = "App " + action + "ed.";
                                        root.refresh();
                                    } else {
                                        root.statusText = "App error: " + (res.error || "");
                                    }
                                });
                            }
                        }
                    }

                    // Port control button
                    Rectangle {
                        width: 60
                        height: 30
                        radius: 6
                        color: portActive ? "#f38ba8" : "#89b4fa"
                        Text { anchors.centerIn: parent; text: portActive ? "Un-Port" : "Port"; color: "#1e1e2e"; font.bold: true; font.pixelSize: 13 }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (portActive) {
                                    root.statusText = "Closing port " + modelData.port + "...";
                                    root.execHelper(["remove", modelData.port.toString(), modelData.protocol], function(res) {
                                        portActive = false;
                                        root.statusText = "Port closed.";
                                    });
                                } else {
                                    root.statusText = "Opening port " + modelData.port + "...";
                                    root.execHelper(["add", modelData.port.toString(), modelData.protocol], function(res) {
                                        if (res.success) {
                                            portActive = true;
                                            root.statusText = "Port is live!";
                                            if (res.ip) root.externalIp = res.ip;
                                        } else {
                                            root.statusText = "Port error: " + (res.error || "");
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

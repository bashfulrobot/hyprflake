import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

// Bar pill shows the open task count (or a status message). The popout lists
// up to five tasks; clicking a row opens its signed launch URL with xdg-open.
// Data comes from the claudoist-top script (path substituted at build time),
// polled once a minute. Nothing is passed through a shell: the script path
// and the launch URL are each one argv element.
PluginComponent {
    id: root

    popoutWidth: 440
    layerNamespacePlugin: "claudoist"

    readonly property string dataScript: "@claudoistTop@"

    property string status: "loading"
    property var items: []
    property int total: 0
    property bool busy: false

    readonly property int pillIconSize: Theme.iconSize - 6

    readonly property string statusText: {
        switch (root.status) {
        case "ok":
            return root.total.toString();
        case "loading":
            return "claudoist: ...";
        case "no-token":
            return "claudoist: no token";
        case "bad-token":
            return "claudoist: bad token";
        default:
            return "claudoist: down";
        }
    }
    readonly property bool failed: root.status !== "ok" && root.status !== "loading"

    function refresh() {
        if (root.busy)
            return;
        root.busy = true;
        Proc.runCommand(null, [root.dataScript], (stdout, exitCode) => {
            root.busy = false;
            let parsed = null;
            try {
                parsed = JSON.parse((stdout || "").trim());
            } catch (e) {
                parsed = null;
            }
            if (exitCode !== 0 || !parsed || !parsed.status) {
                root.status = "down";
                root.items = [];
                root.total = 0;
                return;
            }
            root.status = parsed.status;
            root.items = parsed.items || [];
            root.total = parsed.total || root.items.length;
        }, 0, 15000);
    }

    function openLaunch(url) {
        if (!url)
            return;
        Quickshell.execDetached(["xdg-open", url]);
        root.closePopout();
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: "checklist"
                size: root.pillIconSize
                anchors.verticalCenter: parent.verticalCenter
                color: root.failed ? Theme.error : (root.items.length > 0 ? Theme.primary : Theme.surfaceText)
            }

            StyledText {
                text: root.statusText
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: root.failed ? Theme.error : Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: verticalCol.implicitWidth
            implicitHeight: verticalCol.implicitHeight

            Column {
                id: verticalCol
                anchors.centerIn: parent
                spacing: Theme.spacingS

                DankIcon {
                    name: "checklist"
                    size: root.pillIconSize
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.failed ? Theme.error : (root.items.length > 0 ? Theme.primary : Theme.surfaceText)
                }

                StyledText {
                    text: root.status === "ok" ? root.total.toString() : "!"
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.failed ? Theme.error : Theme.surfaceText
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: "Claudoist"
            showCloseButton: false

            Item {
                width: parent.width
                height: listCol.implicitHeight

                Column {
                    id: listCol
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        width: parent.width
                        visible: root.status !== "ok"
                        text: root.statusText
                        textFormat: Text.PlainText
                        font.pixelSize: Theme.fontSizeMedium
                        color: root.failed ? Theme.error : Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        width: parent.width
                        visible: root.status === "ok" && root.items.length === 0
                        text: "No tasks"
                        textFormat: Text.PlainText
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceVariantText
                    }

                    Repeater {
                        model: root.items

                        StyledRect {
                            required property var modelData
                            width: listCol.width
                            height: rowText.implicitHeight + 2 * Theme.spacingM
                            radius: Theme.cornerRadius
                            opacity: modelData.launch !== "" ? 1.0 : 0.5
                            color: rowArea.containsMouse
                                ? Theme.withAlpha(Theme.primary, 0.12)
                                : Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)

                            Column {
                                id: rowText
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Theme.spacingM
                                spacing: 2

                                StyledText {
                                    width: parent.width
                                    text: modelData.title
                                    textFormat: Text.PlainText
                                    elide: Text.ElideRight
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    width: parent.width
                                    text: modelData.launch !== "" ? modelData.state : modelData.state + " (no launch link)"
                                    textFormat: Text.PlainText
                                    elide: Text.ElideRight
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }
                            }

                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: modelData.launch !== ""
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openLaunch(modelData.launch)
                            }
                        }
                    }

                    StyledRect {
                        width: parent.width
                        height: refreshLabel.implicitHeight + 2 * Theme.spacingS
                        radius: Theme.cornerRadius
                        color: refreshArea.containsMouse
                            ? Theme.withAlpha(Theme.primary, 0.12)
                            : "transparent"

                        StyledText {
                            id: refreshLabel
                            anchors.centerIn: parent
                            text: root.busy ? "Refreshing..." : "Refresh"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        MouseArea {
                            id: refreshArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refresh()
                        }
                    }
                }
            }
        }
    }
}

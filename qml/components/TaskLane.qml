pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "../BarGeometry.js" as BarGeometry

Item {
    id: root

    required property var model
    required property var actions
    required property var applicationCatalog
    required property var pinnedApplications
    required property var windowModel
    required property var bar
    required property real sectionGap
    property string screenName: ""
    property real barHeight: 44
    property real uiScale: 1
    readonly property real buttonHeight: Math.max(24 * uiScale, barHeight - 8 * uiScale)
    readonly property bool overflowing: taskArea.overflowing

    function px(value) {
        return value * uiScale;
    }

    function openContextMenu(address) {
        const expected = String(address || "");
        for (let index = 0; index < taskRepeater.count; index++) {
            const delegate = taskRepeater.itemAt(index);
            if (delegate && delegate.address === expected)
                return delegate.openContextMenu();
        }
        return false;
    }

    clip: true

    Row {
        id: laneRow

        anchors.fill: parent
        spacing: pinRow.visible && taskRow.implicitWidth > 0 ? root.sectionGap : 0

        Row {
            id: pinRow

            anchors.verticalCenter: parent.verticalCenter
            width: implicitWidth
            height: implicitHeight
            visible: pinRepeater.count > 0
            spacing: root.px(2)

            Repeater {
                id: pinRepeater

                model: root.pinnedApplications.pins

                PinnedLauncher {
                    required property string modelData

                    desktopId: modelData
                    uiScale: root.uiScale
                    applicationCatalog: root.applicationCatalog
                    pinnedApplications: root.pinnedApplications
                    windowModel: root.windowModel
                    actions: root.actions
                    bar: root.bar
                }
            }
        }

        Item {
            id: taskArea

            readonly property bool overflowing: BarGeometry.taskOverflowing(taskRow.implicitWidth, width)

            function maximumScroll() {
                return BarGeometry.taskMaximumScroll(taskViewport.contentWidth, taskViewport.width);
            }

            function clampScroll() {
                taskViewport.contentX = BarGeometry.taskScrollOffset(taskViewport.contentX, 0, taskViewport.contentWidth, taskViewport.width);
            }

            function scrollBy(amount) {
                taskViewport.contentX = BarGeometry.taskScrollOffset(taskViewport.contentX, amount, taskViewport.contentWidth, taskViewport.width);
            }

            width: Math.max(0, laneRow.width - pinRow.width - laneRow.spacing)
            height: root.height

            onOverflowingChanged: {
                if (!overflowing)
                    taskViewport.contentX = 0;
                else
                    clampScroll();
            }
            onWidthChanged: clampScroll()

            Flickable {
                id: taskViewport

                anchors.fill: parent
                anchors.leftMargin: taskArea.overflowing ? earlierTasksButton.width : 0
                anchors.rightMargin: taskArea.overflowing ? moreTasksButton.width : 0
                contentWidth: taskRow.implicitWidth
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                interactive: taskArea.overflowing
                layer.enabled: taskArea.overflowing
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: taskFadeMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }

                onContentWidthChanged: taskArea.clampScroll()

                Row {
                    id: taskRow

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.px(4)

                    Repeater {
                        id: taskRepeater

                        model: root.model

                        Item {
                            id: taskDelegate

                            required property string address
                            required property string title
                            required property string appId
                            required property string desktopId
                            required property string iconName
                            required property bool active
                            required property bool urgent
                            required property bool minimized
                            required property bool fullscreen
                            required property bool maximized
                            required property bool floating

                            function openContextMenu() {
                                return taskButton.openContextMenu();
                            }

                            width: taskButton.implicitWidth
                            height: taskButton.implicitHeight

                            TaskButton {
                                id: taskButton

                                anchors.fill: parent
                                windowAddress: taskDelegate.address
                                title: taskDelegate.title
                                appId: taskDelegate.appId
                                desktopId: taskDelegate.desktopId
                                iconName: taskDelegate.iconName
                                windowActive: taskDelegate.active
                                urgent: taskDelegate.urgent
                                minimized: taskDelegate.minimized
                                fullscreen: taskDelegate.fullscreen
                                maximized: taskDelegate.maximized
                                floating: taskDelegate.floating
                                uiScale: root.uiScale
                                buttonHeight: root.buttonHeight
                                actions: root.actions
                                applicationCatalog: root.applicationCatalog
                                pinnedApplications: root.pinnedApplications
                                bar: root.bar
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: taskFadeMask

                readonly property real fadeFraction: Math.min(0.5, root.px(24) / Math.max(1, width))

                width: taskViewport.width
                height: taskViewport.height
                visible: false
                layer.enabled: taskArea.overflowing
                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        position: 0
                        color: earlierTasksButton.enabled ? "transparent" : "white"
                    }

                    GradientStop {
                        position: taskFadeMask.fadeFraction
                        color: "white"
                    }

                    GradientStop {
                        position: 1 - taskFadeMask.fadeFraction
                        color: "white"
                    }

                    GradientStop {
                        position: 1
                        color: moreTasksButton.enabled ? "transparent" : "white"
                    }
                }
            }

            TaskScrollButton {
                id: earlierTasksButton

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: taskArea.overflowing
                enabled: taskViewport.contentX > 0.5
                pointsLeft: true
                buttonHeight: root.buttonHeight
                hintText: "Earlier tasks"
                uiScale: root.uiScale
                bar: root.bar
                onClicked: taskArea.scrollBy(-Math.min(root.px(180), Math.max(root.px(90), taskViewport.width * 0.55)))
            }

            TaskScrollButton {
                id: moreTasksButton

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: taskArea.overflowing
                enabled: taskViewport.contentX < taskArea.maximumScroll() - 0.5
                buttonHeight: root.buttonHeight
                hintText: "More tasks"
                uiScale: root.uiScale
                bar: root.bar
                onClicked: taskArea.scrollBy(Math.min(root.px(180), Math.max(root.px(90), taskViewport.width * 0.55)))
            }
        }
    }
}

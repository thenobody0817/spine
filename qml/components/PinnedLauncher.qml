pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../AppIdentity.js" as AppIdentity
import "../HintLogic.js" as HintLogic
import "../PinState.js" as PinState
import qs.Commons as Commons

Rectangle {
    id: root

    required property string desktopId
    required property var applicationCatalog
    required property var pinnedApplications
    required property var windowModel
    property var bar: null
    property var actions: null
    property real uiScale: 1
    property bool launching: false
    property bool controlOnPress: false
    property int cycleIndex: -1
    readonly property int applicationIndexRevision: applicationCatalog ? applicationCatalog.indexRevision : 0
    readonly property int identityRevision: applicationCatalog ? applicationCatalog.revision : 0
    readonly property int windowRevision: windowModel ? windowModel.revision : 0
    readonly property int pinRevision: pinnedApplications ? pinnedApplications.revision : 0
    readonly property var entry: {
        applicationIndexRevision;
        return applicationCatalog ? applicationCatalog.presentationForId(desktopId) : null;
    }
    readonly property string label: String(entry ? entry.name || desktopId : desktopId)
    readonly property string iconName: String(entry ? entry.icon || "" : "") || "application-x-executable"
    readonly property string iconSource: applicationCatalog.iconSource(iconName)
    readonly property bool tooltipHovered: pointer.containsMouse
    // Window state comes from the shared unfiltered model. A minimized window
    // leaves its monitor's filtered list, so a per-monitor model would lose
    // the pin's running state at the moment it matters most.
    readonly property var running: {
        windowRevision;
        identityRevision;
        pinRevision;
        return PinState.forPin(windowTasks(), desktopId, matchesPin);
    }
    readonly property string runningState: PinState.indicator(running)
    readonly property string hintText: HintLogic.pinnedApplication(label, bar ? bar.shortcut(label) : "", runningState, running.count)
    readonly property string accessibleDescription: {
        if (!entry)
            return "Pinned application is unavailable";
        if (runningState === "none")
            return "Pinned application";
        if (runningState === "urgent")
            return "Pinned application with a window requesting attention";
        if (runningState === "focused")
            return "Pinned application with a focused window";
        if (runningState === "minimized")
            return running.count > 1 ? "Pinned application with " + running.count + " minimized windows" : "Pinned application with a minimized window";
        return running.count > 1 ? "Pinned application with " + running.count + " open windows" : "Pinned application with an open window";
    }

    function px(value) {
        return value * uiScale;
    }

    // Both sides are compared the same way. Stored pins and resolved window
    // identities differ only by case and an optional .desktop suffix.
    function matchesPin(candidate) {
        const key = AppIdentity.normalized(candidate);
        return key !== "" && key === AppIdentity.normalized(desktopId);
    }

    function windowTasks() {
        if (!applicationCatalog || !windowModel || typeof windowModel.records !== "function")
            return [];
        return AppIdentity.taskRecords(windowModel.records(), record => applicationCatalog.identityFor(record));
    }

    function launch(floating) {
        if (!applicationCatalog.launch(desktopId, floating === true))
            return;
        launching = true;
        launchFeedback.restart();
    }

    function launchFromPointer(modifiers) {
        if (!applicationCatalog.launchFromPointer(desktopId, modifiers))
            return;
        launching = true;
        launchFeedback.restart();
    }

    function triggerPrimary() {
        const windows = running.windows;
        if (windows.length === 0) {
            launch();
            return true;
        }
        if (!actions)
            return false;
        if (windows.length === 1) {
            cycleIndex = 0;
            actions.toggle(windows[0].address);
            return true;
        }
        // Several windows: focus the most recent one, then step through the
        // app's windows on further clicks.
        cycleIndex = (cycleIndex + 1) % windows.length;
        const target = windows[cycleIndex];
        actions.invoke(target.address, target.minimized ? "restore" : "activate");
        return true;
    }

    function triggerPress(button) {
        if (bar)
            bar.hideTooltip(root);
        if (button === Qt.RightButton) {
            contextMenu.open = !contextMenu.open;
            return true;
        }
        if (button === Qt.LeftButton) {
            if (bar && bar.activePopout && typeof bar.activePopout.close === "function")
                bar.activePopout.close();
            if (controlOnPress)
                launchFromPointer(Qt.ControlModifier);
            else
                triggerPrimary();
            controlOnPress = false;
            return true;
        }
        controlOnPress = false;
        return false;
    }

    width: px(32)
    height: px(32)
    radius: px(4)
    color: pointer.pressed ? Commons.Style.pressedFillFor(Commons.Color.bar.text, Commons.Color.accent, Commons.Color.urgent) : pointer.containsMouse || contextMenu.open || activeFocus ? Commons.Style.hoverFillFor(Commons.Color.bar.text, Commons.Color.accent, Commons.Color.urgent) : "transparent"
    border.color: Commons.Color.accent
    border.width: activeFocus ? Math.max(1, Math.round(px(1))) : 0
    opacity: entry ? 1 : 0.58
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: entry ? "Launch " + label : "Missing pinned application " + label
    Accessible.description: accessibleDescription
    Accessible.onPressAction: triggerPrimary()

    Component.onCompleted: {
        if (bar && typeof bar.registerClickTarget === "function")
            bar.registerClickTarget(root);
    }
    Component.onDestruction: {
        if (bar && typeof bar.unregisterClickTarget === "function")
            bar.unregisterClickTarget(root);
    }

    Image {
        id: iconImage

        anchors.centerIn: parent
        width: root.px(20)
        height: width
        source: root.iconSource
        sourceSize.width: width * Screen.devicePixelRatio
        sourceSize.height: height * Screen.devicePixelRatio
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        retainWhileLoading: true
        opacity: root.runningState === "minimized" ? 0.55 : 1
    }

    Text {
        anchors.centerIn: parent
        visible: root.iconSource === "" || iconImage.status === Image.Error
        text: root.label.slice(0, 1).toUpperCase()
        textFormat: Text.PlainText
        color: Commons.Color.bar.text
        font.family: Commons.Style.font.family
        font.pixelSize: Commons.Style.font.body
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Commons.Util.alpha(Commons.Color.accent, 0.18)
        visible: root.launching

        SequentialAnimation on opacity {
            running: root.launching && !(root.bar && root.bar.reducedMotion === true)
            loops: Animation.Infinite

            NumberAnimation {
                to: 0.4
                duration: 1100
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: 1
                duration: 1100
                easing.type: Easing.InOutSine
            }
        }
    }

    Rectangle {
        id: countBadge

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: root.px(1)
        anchors.topMargin: root.px(1)
        visible: root.running.count > 1
        width: countLabel.implicitWidth + root.px(4)
        height: countLabel.implicitHeight + root.px(1)
        radius: height / 2
        color: Commons.Color.bar.background
        border.color: Commons.Color.accent
        border.width: Math.max(1, Math.round(root.px(1)))

        Text {
            id: countLabel

            anchors.centerIn: parent
            text: String(root.running.count)
            textFormat: Text.PlainText
            color: Commons.Color.bar.text
            font.family: Commons.Style.font.family
            font.pixelSize: Commons.Style.font.caption
        }
    }

    Timer {
        id: launchFeedback

        interval: 2200
        onTriggered: root.launching = false
    }

    // Running indicator. A full accent underline marks the focused window, a
    // shorter one marks a plain running app, urgent wins over focused, and a
    // minimized app dims instead of highlighting.
    Rectangle {
        id: runningUnderline

        readonly property bool full: root.runningState === "focused" || root.runningState === "urgent"

        visible: root.running.count > 0
        height: root.px(2)
        radius: height / 2
        color: root.runningState === "urgent" ? Commons.Color.urgent : root.runningState === "minimized" ? Commons.Util.alpha(Commons.Color.accent, 0.45) : Commons.Color.accent
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: full ? Math.max(root.px(10), parent.width - root.px(10)) : Math.max(root.px(10), Math.round(parent.width * 0.55))
    }

    // The running indicator supersedes this one, so the two never stack.
    Rectangle {
        visible: contextMenu.open && running.count === 0
        width: Math.max(root.px(10), Math.round(parent.width * 0.55))
        height: root.px(2)
        radius: height / 2
        color: Commons.Color.accent
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    TaskContextMenu {
        id: contextMenu

        anchorItem: root
        desktopId: root.desktopId
        launcherOnly: true
        pinState: root.running
        applicationCatalog: root.applicationCatalog
        pinnedApplications: root.pinnedApplications
        actions: root.actions
        bar: root.bar
    }

    BarMouseArea {
        id: pointer

        bar: root.bar
        forwardPress: function (button) {
            return root.triggerPress(button);
        }

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.entry ? Qt.PointingHandCursor : Qt.ArrowCursor

        onEntered: if (root.bar)
            root.bar.showTooltip(root, root.hintText, 550)
        onExited: if (root.bar)
            root.bar.hideTooltip(root)
        onPressed: function (event) {
            root.controlOnPress = event.button === Qt.LeftButton && (event.modifiers & Qt.ControlModifier) !== 0;
        }
        onCanceled: root.controlOnPress = false
        onClicked: function (event) {
            root.controlOnPress = root.controlOnPress || (event.modifiers & Qt.ControlModifier) !== 0;
            root.triggerPress(event.button);
        }
    }

    Keys.onSpacePressed: triggerPrimary()
    Keys.onReturnPressed: triggerPrimary()
    Keys.onEnterPressed: triggerPrimary()
    Keys.onMenuPressed: contextMenu.open = !contextMenu.open
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import "WindowState.js" as WindowState

Item {
    id: root

    property alias model: windows
    property int revision: 0
    property bool initialized: false
    property int nextGeneration: 1
    property int nextOrder: 1
    property var sourcesByAddress: ({})
    readonly property string applicationProbePath: decodeURIComponent(String(Qt.resolvedUrl("../../scripts/window-application-identities")).replace(/^file:\/\//, ""))

    function allocateGeneration() {
        return nextGeneration++;
    }

    function indexForAddress(address) {
        const expected = WindowState.normalizeAddress(address);
        for (let index = 0; index < windows.count; index++) {
            if (windows.get(index).address === expected)
                return index;
        }
        return -1;
    }

    function toplevelFor(address) {
        return sourcesByAddress[WindowState.normalizeAddress(address)] || null;
    }

    function recordFor(address) {
        const index = indexForAddress(WindowState.normalizeAddress(address));
        return index === -1 ? null : WindowState.copyRecord(windows.get(index));
    }

    function records() {
        const result = [];
        for (let index = 0; index < windows.count; index++)
            result.push(WindowState.copyRecord(windows.get(index)));
        return result;
    }

    function addressForPid(pid) {
        const expected = Number(pid || 0);
        if (expected <= 0)
            return "";
        for (let index = 0; index < windows.count; index++) {
            if (Number(windows.get(index).pid) === expected)
                return String(windows.get(index).address || "");
        }
        return "";
    }

    function addressForAppId(appId) {
        const expected = String(appId || "").toLowerCase();
        if (expected === "")
            return "";
        for (let index = 0; index < windows.count; index++) {
            if (String(windows.get(index).appId || "").toLowerCase() === expected)
                return String(windows.get(index).address || "");
        }
        return "";
    }

    function rememberSource(address, source) {
        const next = ({});
        for (const key in sourcesByAddress)
            next[key] = sourcesByAddress[key];
        next[address] = source;
        sourcesByAddress = next;
    }

    function forgetSource(address, source) {
        if (sourcesByAddress[address] !== source)
            return;

        const next = ({});
        for (const key in sourcesByAddress) {
            if (key !== address)
                next[key] = sourcesByAddress[key];
        }
        sourcesByAddress = next;
    }

    function closeTracker(tracker) {
        if (tracker && typeof tracker.closeRecord === "function")
            tracker.closeRecord();
    }

    function upsert(raw, source) {
        const address = WindowState.normalizeAddress(raw.address);
        if (address === "")
            return;

        const index = indexForAddress(address);
        raw.address = address;
        const creationOrder = WindowState.creationOrder(raw.stableId);
        raw.orderKey = creationOrder || (index === -1 ? nextOrder++ : windows.get(index).orderKey);
        nextOrder = Math.max(nextOrder, raw.orderKey + 1);
        const record = WindowState.normalizeRecord(raw);
        rememberSource(address, source);
        if (index === -1) {
            windows.append(record);
            revision++;
        } else if (!WindowState.sameRecord(windows.get(index), record)) {
            windows.set(index, record);
            revision++;
        }
    }

    function remove(address, generation, source) {
        const key = WindowState.normalizeAddress(address);
        const index = indexForAddress(key);
        if (index === -1 || windows.get(index).generation !== generation)
            return;

        windows.remove(index);
        forgetSource(key, source);
        revision++;
    }

    visible: false

    ListModel {
        id: windows

        dynamicRoles: true
    }

    // New windows can lack IPC details. Floating changes also need a fresh
    // snapshot because Quickshell has no dedicated floating property.
    // Batch both requests without polling or postponing an existing refresh.
    Timer {
        id: windowDetailsRefresh

        interval: 50
        onTriggered: Hyprland.refreshToplevels()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "changefloatingmode" && !windowDetailsRefresh.running)
                windowDetailsRefresh.start();
        }
    }

    Instantiator {
        model: Hyprland.toplevels

        delegate: Item {
            id: tracker

            required property var modelData
            property int generation: 0
            property string registeredAddress: ""
            property var registeredWayland: null
            property bool closing: false
            property int probedPid: 0
            property bool requestedWindowDetails: false
            property int identityProbeAttempts: 0
            property var terminalPrograms: []
            readonly property int maxIdentityProbeAttempts: 4

            function applyPrograms(text) {
                const result = WindowState.parseTerminalProbe(text);
                terminalPrograms = result.programs;
                sync();
                if (WindowState.retryTerminalProbe(result, identityProbeAttempts, maxIdentityProbeAttempts))
                    identityProbeDelay.restart();
            }

            function scheduleIdentityProbe(pid) {
                const expected = Math.max(0, Math.round(Number(pid || 0)));
                if (expected <= 0 || expected === probedPid)
                    return;
                probedPid = expected;
                identityProbeAttempts = 0;
                terminalPrograms = [];
                identityProbeDelay.restart();
            }

            function closeRecord() {
                if (closing)
                    return;

                closing = true;
                root.remove(registeredAddress, generation, modelData);
            }

            function rawRecord() {
                const toplevel = modelData;
                const ipc = toplevel && toplevel.lastIpcObject ? toplevel.lastIpcObject : ({});
                const wayland = toplevel ? toplevel.wayland : null;
                const workspace = toplevel ? toplevel.workspace : null;
                const monitor = toplevel ? toplevel.monitor : null;
                const workspaceSnapshot = ipc.workspace || ({});
                return {
                    "address": toplevel ? String(toplevel.address || "") : "",
                    "title": toplevel ? String(toplevel.title || (wayland ? wayland.title : "") || "") : "",
                    "waylandAppId": wayland ? String(wayland.appId || "") : "",
                    "className": String(ipc.class || ""),
                    "initialClass": String(ipc.initialClass || ""),
                    "pid": Number(ipc.pid || 0),
                    "stableId": ipc.stableId,
                    "terminalPrograms": terminalPrograms,
                    "desktopEntryId": "",
                    "workspaceId": workspace ? Number(workspace.id || 0) : Number(workspaceSnapshot.id || 0),
                    "workspaceName": workspace ? String(workspace.name || "") : String(workspaceSnapshot.name || ""),
                    "monitorId": monitor ? Number(monitor.id) : Number(ipc.monitor === undefined ? -1 : ipc.monitor),
                    "monitorName": monitor ? String(monitor.name || "") : "",
                    "active": (toplevel && toplevel.activated === true) || (wayland && wayland.activated === true),
                    "urgent": toplevel && toplevel.urgent === true,
                    "minimized": wayland && wayland.minimized === true,
                    "fullscreen": (wayland && wayland.fullscreen === true) || (Number(ipc.fullscreen || ipc.fullscreenClient || 0) & 2) !== 0,
                    "maximized": (wayland && wayland.maximized === true) || (Number(ipc.fullscreen || ipc.fullscreenClient || 0) & 1) !== 0,
                    "floating": ipc.floating === true,
                    "mapped": ipc.mapped !== false,
                    "hidden": ipc.hidden === true,
                    "xwayland": ipc.xwayland === true,
                    "hasWaylandHandle": wayland !== null,
                    "generation": generation
                };
            }

            function sync() {
                if (closing)
                    return;

                const currentAddress = modelData ? WindowState.normalizeAddress(modelData.address) : "";
                const currentWayland = modelData ? modelData.wayland : null;
                if (registeredWayland !== null && currentWayland === null) {
                    closeRecord();
                    return;
                }
                if (registeredAddress !== "" && registeredAddress !== currentAddress)
                    root.remove(registeredAddress, generation, modelData);

                registeredAddress = currentAddress;
                registeredWayland = currentWayland;
                const raw = rawRecord();
                root.upsert(raw, modelData);
                if (currentAddress !== "" && raw.pid <= 0 && !requestedWindowDetails) {
                    requestedWindowDetails = true;
                    if (!windowDetailsRefresh.running)
                        windowDetailsRefresh.start();
                }
                scheduleIdentityProbe(raw.pid);
            }

            visible: false
            Component.onCompleted: {
                generation = root.allocateGeneration();
                sync();
            }
            Component.onDestruction: closeRecord()

            Timer {
                id: identityProbeDelay

                interval: tracker.identityProbeAttempts === 0 ? 250 : 350
                onTriggered: if (!identityProbe.running) {
                    tracker.identityProbeAttempts++;
                    identityProbe.running = true;
                }
            }

            Process {
                id: identityProbe

                command: [root.applicationProbePath, String(tracker.probedPid)]
                stdout: StdioCollector {
                    onStreamFinished: tracker.applyPrograms(text)
                }
            }

            Connections {
                function onAddressChanged() {
                    tracker.sync();
                }

                function onTitleChanged() {
                    tracker.sync();
                }

                function onActivatedChanged() {
                    tracker.sync();
                }

                function onUrgentChanged() {
                    tracker.sync();
                }

                function onWorkspaceChanged() {
                    tracker.sync();
                }

                function onMonitorChanged() {
                    tracker.sync();
                }

                function onLastIpcObjectChanged() {
                    tracker.sync();
                }

                function onWaylandHandleChanged() {
                    tracker.sync();
                }

                target: tracker.modelData
                ignoreUnknownSignals: true
            }

            Connections {
                function onAppIdChanged() {
                    tracker.sync();
                }

                function onTitleChanged() {
                    tracker.sync();
                }

                function onActivatedChanged() {
                    tracker.sync();
                }

                function onMaximizedChanged() {
                    tracker.sync();
                }

                function onMinimizedChanged() {
                    tracker.sync();
                }

                function onFullscreenChanged() {
                    tracker.sync();
                }

                function onClosed() {
                    tracker.closeRecord();
                }

                target: tracker.modelData ? tracker.modelData.wayland : null
                ignoreUnknownSignals: true
            }
        }

        onObjectRemoved: (index, object) => root.closeTracker(object)
    }

    Component.onCompleted: Qt.callLater(() => initialized = true)
}

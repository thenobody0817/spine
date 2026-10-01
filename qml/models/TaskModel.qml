pragma ComponentBehavior: Bound

import QtQuick
import "../AppIdentity.js" as AppIdentity

Item {
    id: root

    required property var sourceModel
    required property int sourceRevision
    required property var applicationCatalog
    required property int applicationRevision
    property var pinnedApplications: null
    readonly property int pinRevision: pinnedApplications ? pinnedApplications.revision : 0
    property alias model: tasks

    function recordAt(index) {
        const value = sourceModel.get(index);
        return {
            "address": String(value.address || ""),
            "title": String(value.title || ""),
            "appId": String(value.appId || ""),
            "className": String(value.className || ""),
            "initialClass": String(value.initialClass || ""),
            "desktopEntryId": String(value.desktopEntryId || ""),
            "terminalPrograms": String(value.terminalPrograms || "[]"),
            "active": value.active === true,
            "urgent": value.urgent === true,
            "minimized": value.minimized === true,
            "fullscreen": value.fullscreen === true,
            "maximized": value.maximized === true,
            "floating": value.floating === true,
            "orderKey": Number(value.orderKey || index + 1)
        };
    }

    function isPinnedTask(task) {
        return pinnedApplications && pinnedApplications.isPinnedNormalized(task.desktopId);
    }

    function rebuild() {
        const records = [];
        for (let index = 0; index < sourceModel.count; index++)
            records.push(recordAt(index));
        const resolved = AppIdentity.taskRecords(records, record => applicationCatalog.identityFor(record));
        // A pinned app shows its running state on the pin, so its own task
        // buttons are dropped. An unresolved identity matches no pin and stays.
        const taskRecords = pinnedApplications ? resolved.filter(task => !isPinnedTask(task)) : resolved;

        // Keep delegates (and the lane's scroll position) across state and
        // metadata changes. Opening order belongs to the window, not its state.
        for (let taskIndex = 0; taskIndex < taskRecords.length; taskIndex++) {
            const task = taskRecords[taskIndex];
            let currentIndex = taskIndex;
            while (currentIndex < tasks.count && tasks.get(currentIndex).address !== task.address)
                currentIndex++;
            if (currentIndex === tasks.count) {
                tasks.insert(taskIndex, task);
            } else {
                if (currentIndex !== taskIndex)
                    tasks.move(currentIndex, taskIndex, 1);
                for (const role in task) {
                    if (tasks.get(taskIndex)[role] !== task[role])
                        tasks.setProperty(taskIndex, role, task[role]);
                }
            }
        }
        while (tasks.count > taskRecords.length)
            tasks.remove(tasks.count - 1);
    }

    visible: false

    onSourceRevisionChanged: rebuild()
    onApplicationRevisionChanged: rebuild()
    onPinRevisionChanged: rebuild()
    Component.onCompleted: rebuild()

    ListModel {
        id: tasks

        dynamicRoles: true
    }
}

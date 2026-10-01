.pragma library

// Running state for one taskbar pin, derived from the shared unfiltered
// window model. Kept import-free so it runs without a compositor.
//
// A QML JavaScript library cannot import another library, so the desktop-entry
// comparison arrives as the `matches` predicate supplied by the caller.

function aggregate(desktopId, windows) {
    var active = false;
    var urgent = false;
    var minimized = 0;
    for (var index = 0; index < windows.length; index++) {
        if (windows[index].active === true)
            active = true;
        if (windows[index].urgent === true)
            urgent = true;
        if (windows[index].minimized === true)
            minimized++;
    }
    return {
        "desktopId": String(desktopId || ""),
        "count": windows.length,
        "active": active,
        "urgent": urgent,
        "anyMinimized": minimized > 0,
        "allMinimized": windows.length > 0 && minimized === windows.length,
        "windows": windows
    };
}

function record(task, index) {
    return {
        "address": String(task.address || ""),
        "title": String(task.title || ""),
        "desktopId": String(task.desktopId || ""),
        "active": task.active === true,
        "urgent": task.urgent === true,
        "minimized": task.minimized === true,
        "orderKey": Number(task.orderKey || index + 1)
    };
}

function mostRecentFirst(windows) {
    // Hyprland's creation ID is the only ordering signal the model keeps, so
    // "most recent" means the highest one, matching the task list rule.
    windows.sort(function (first, second) {
        if (second.orderKey !== first.orderKey)
            return second.orderKey - first.orderKey;
        return String(second.address).localeCompare(String(first.address));
    });
    return windows;
}

function forPin(records, desktopId, matches) {
    const windows = [];
    const tasks = records || [];
    // A blank pin can never own a window, whatever its predicate says.
    if (String(desktopId || "").trim() === "")
        return aggregate(desktopId, windows);
    const match = typeof matches === "function" ? matches : function () {
        return false;
    };
    for (var index = 0; index < tasks.length; index++) {
        const task = tasks[index];
        if (!task || !match(task.desktopId))
            continue;
        windows.push(record(task, index));
    }
    return aggregate(desktopId, mostRecentFirst(windows));
}

function empty(desktopId) {
    return aggregate(desktopId, []);
}

// One word per visual state. Urgent outranks focused. A pin only reads as
// minimized when every one of its windows is hidden; a hidden window beside a
// visible one is still a running app.
function indicator(state) {
    if (!state || Number(state.count || 0) <= 0)
        return "none";
    if (state.urgent === true)
        return "urgent";
    if (state.active === true)
        return "focused";
    if (state.allMinimized === true)
        return "minimized";
    return "running";
}

function windowStateLabel(window) {
    if (!window)
        return "";
    if (window.urgent === true)
        return "Urgent";
    if (window.active === true)
        return "Active";
    if (window.minimized === true)
        return "Minimized";
    return "";
}

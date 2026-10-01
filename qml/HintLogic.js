.pragma library

function displayKey(value) {
    var key = String(value || "").toUpperCase();
    var names = {
        "BACKSPACE": "Backspace",
        "DELETE": "Delete",
        "ESCAPE": "Esc",
        "HOME": "Home",
        "MINUS": "−",
        "RETURN": "Enter",
        "SPACE": "Space",
        "TAB": "Tab"
    };
    if (names[key])
        return names[key];
    if (key.indexOf("XF86") === 0)
        return key.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2");
    return key.split(" ").map(function (part) {
        return part.length > 1 ? part.charAt(0) + part.slice(1).toLowerCase() : part;
    }).join(" ");
}

function displayShortcut(value) {
    var tokens = String(value || "").trim().replace(/\s*\+\s*/g, " ").split(/\s+/);
    var modifiers = [];
    var key = [];
    for (var index = 0; index < tokens.length; index++) {
        var token = tokens[index].toUpperCase();
        if (key.length === 0 && ["SUPER", "CTRL", "CONTROL", "ALT", "SHIFT"].indexOf(token) !== -1) {
            if (token === "SUPER")
                modifiers.push("Super");
            else if (token === "CTRL" || token === "CONTROL")
                modifiers.push("Ctrl");
            else if (token === "ALT")
                modifiers.push("Alt");
            else
                modifiers.push("Shift");
        } else {
            key.push(tokens[index]);
        }
    }
    var primary = key.length ? displayKey(key.join(" ")) : "";
    if (modifiers.length && primary !== "")
        return modifiers.join(" ") + " + " + primary;
    if (modifiers.length)
        return modifiers.join(" ");
    return primary;
}

function parseShortcuts(text) {
    var result = ({});
    var lines = String(text || "").split(/\r?\n/);
    for (var index = 0; index < lines.length; index++) {
        var separator = lines[index].indexOf("→");
        if (separator < 0)
            continue;
        var keys = displayShortcut(lines[index].slice(0, separator));
        var description = lines[index].slice(separator + 1).trim();
        if (keys !== "" && description !== "" && result[description] === undefined)
            result[description] = keys;
    }
    return result;
}

function withShortcut(action, shortcut) {
    var cleanAction = String(action || "").trim();
    var cleanShortcut = String(shortcut || "").trim();
    return cleanShortcut === "" ? cleanAction : cleanAction + " (" + cleanShortcut + ")";
}

function application(label, shortcut) {
    return withShortcut(String(label || "Application"), shortcut);
}

function pinnedApplication(label, shortcut, state, count) {
    var text = String(label || "Application");
    var total = Math.max(0, Math.round(Number(count || 0)));
    var detail = "";
    if (String(state || "none") === "urgent")
        detail = "needs attention";
    else if (String(state || "none") === "focused")
        detail = "focused";
    else if (String(state || "none") === "minimized")
        detail = total > 1 ? total + " minimized windows" : "minimized";
    else if (total > 1)
        detail = total + " windows";
    return withShortcut(detail === "" ? text : text + ", " + detail, shortcut);
}

function startIndicator(id, active) {
    var key = String(id || "");
    if (key === "Dictation")
        return active === true ? "Dictation active" : "Dictate";
    if (key === "ScreenRecording")
        return active === true ? "Stop recording" : "Screen Recording";
    if (key === "Reminder")
        return active === true ? "Show Reminders" : "Set Reminder";
    if (key === "NightLight")
        return active === true ? "Day Light" : "Night Light";
    if (key === "Dnd")
        return active === true ? "Allow Notifications" : "Silence Notifications";
    if (key === "StayAwake")
        return active === true ? "Allow Idle Lock & Screensaver" : "Stay Awake";
    return key.replace(/([a-z0-9])([A-Z])/g, "$1 $2");
}

function task(title) {
    return String(title || "Application");
}

function tray(label) {
    return String(label || "Tray application");
}

function workspaceMoveShortcuts(shortcuts) {
    var groups = [];
    var arrows = {
        "Left": "←",
        "Right": "→",
        "Up": "↑",
        "Down": "↓"
    };
    (shortcuts || []).forEach(function (shortcut) {
        if (!shortcut)
            return;
        var split = shortcut.lastIndexOf(" + ");
        var prefix = split < 0 ? "" : shortcut.slice(0, split + 3);
        var key = shortcut.slice(split < 0 ? 0 : split + 3);
        key = arrows[key] || key;
        var group = groups.filter(function (item) {
            return item.prefix === prefix;
        })[0];
        if (!group) {
            group = {
                "prefix": prefix,
                "keys": []
            };
            groups.push(group);
        }
        if (group.keys.indexOf(key) === -1)
            group.keys.push(key);
    });
    return groups.map(function (group) {
        return group.prefix + group.keys.join("/");
    }).join(", ");
}

function workspace(shortcut, monitorCount, moveShortcuts) {
    var family = String(shortcut || "").replace(/\s*\+\s*1$/, " + 1, 2, …");
    var hint = withShortcut("Switch workspace", family);
    if (monitorCount > 1)
        hint += "\n" + withShortcut("Move current workspace to a different monitor", workspaceMoveShortcuts(moveShortcuts));
    return hint;
}

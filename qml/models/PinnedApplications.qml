pragma ComponentBehavior: Bound

import QtQuick
import "../AppIdentity.js" as AppIdentity

QtObject {
    id: root

    property var settings: null
    property string settingsKey: "tilelanePins"
    readonly property var pins: settings ? settings.values[settingsKey] || [] : []
    property int revision: 0
    readonly property bool loaded: settings && settings.loaded
    readonly property string lastError: settings ? settings.lastError : ""

    onPinsChanged: revision++

    function persist(nextPins) {
        return settings ? settings.setValue(settingsKey, nextPins) : false;
    }

    function isPinned(desktopId) {
        return pins.indexOf(String(desktopId || "")) !== -1;
    }

    // Stored pins and resolved window identities differ only by case and an
    // optional .desktop suffix, because Quickshell strips that suffix from
    // entry.id. Compare both sides the same way, or pinning silently stops
    // matching the windows it is supposed to collapse.
    function isPinnedNormalized(desktopId) {
        const key = AppIdentity.normalized(desktopId);
        if (key === "")
            return false;
        return pins.some(function (pin) {
            return AppIdentity.normalized(pin) === key;
        });
    }

    function pin(desktopId) {
        const id = String(desktopId || "");
        if (!AppIdentity.validDesktopId(id) || isPinned(id))
            return false;
        const next = pins.slice(0);
        next.push(id);
        return persist(next);
    }

    function unpin(desktopId) {
        const id = String(desktopId || "");
        const index = pins.indexOf(id);
        if (index === -1)
            return false;
        const next = pins.slice(0);
        next.splice(index, 1);
        return persist(next);
    }

    function toggle(desktopId) {
        return isPinned(desktopId) ? unpin(desktopId) : pin(desktopId);
    }

    function move(desktopId, offset) {
        const id = String(desktopId || "");
        const from = pins.indexOf(id);
        const to = Math.max(0, Math.min(pins.length - 1, from + Number(offset || 0)));
        if (from === -1 || from === to)
            return false;
        const next = pins.slice(0);
        next.splice(from, 1);
        next.splice(to, 0, id);
        return persist(next);
    }
}

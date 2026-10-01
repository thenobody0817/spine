pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../SettingsLogic.js" as SettingsLogic

QtObject {
    id: root

    property var shell: null
    property var barConfig: ({})
    property string pluginId: "io.github.thenobody0817.spine"
    readonly property var values: SettingsLogic.read(barConfig)
    readonly property bool active: barConfig && barConfig.id === pluginId
    readonly property bool loaded: active && barConfig.tilelaneSettingsVersion === 1
    readonly property bool needsMigration: active && barConfig.tilelaneSettingsVersion === undefined
    readonly property string configBase: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    property string legacyPath: configBase + "/tilelane/pins.json"
    property string migrationError: ""
    property var legacy: null
    readonly property string lastError: migrationError || (active && barConfig.tilelaneSettingsVersion !== undefined && barConfig.tilelaneSettingsVersion !== 1 ? "Unsupported Tilelane settings version" : values.errors.join("; "))

    onLastErrorChanged: if (lastError)
        console.warn("Tilelane settings: " + lastError)
    onShellChanged: Qt.callLater(initialize)
    onNeedsMigrationChanged: Qt.callLater(initialize)
    onLegacyChanged: Qt.callLater(initialize)

    function initialize() {
        if (!needsMigration || !legacy || !shell || typeof shell.mutateShellConfig !== "function")
            return false;
        return shell.mutateShellConfig(function (config) {
            if (config.bar && config.bar.id === root.pluginId)
                SettingsLogic.initialize(config.bar, root.legacy);
        });
    }

    function setValue(key, value) {
        if (!loaded || !shell || typeof shell.mutateShellConfig !== "function")
            return false;
        let next;
        try {
            next = SettingsLogic.field(key, value);
        } catch (error) {
            return false;
        }
        if (JSON.stringify(barConfig[key]) === JSON.stringify(next))
            return false;
        let changed = false;
        const accepted = shell.mutateShellConfig(function (config) {
            if (!config.bar || config.bar.id !== root.pluginId || config.bar.tilelaneSettingsVersion !== 1)
                return;
            if (JSON.stringify(config.bar[key]) !== JSON.stringify(next)) {
                config.bar[key] = next;
                changed = true;
            }
        });
        return accepted === true && changed;
    }

    property FileView legacyFile: FileView {
        path: root.needsMigration ? root.legacyPath : ""
        printErrors: false

        onLoaded: {
            try {
                root.legacy = SettingsLogic.legacyPreferences(text());
                root.migrationError = "";
            } catch (error) {
                root.migrationError = "Cannot import old preferences: " + error;
            }
        }
        onLoadFailed: function (error) {
            if (!root.needsMigration)
                return;
            if (error === FileViewError.FileNotFound) {
                root.legacy = SettingsLogic.legacyPreferences("");
                root.migrationError = "";
            } else {
                root.migrationError = "Cannot read old preferences: " + FileViewError.toString(error);
            }
        }
    }
}

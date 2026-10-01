import QtQuick
import QtTest
import "../../qml/HintLogic.js" as HintLogic

TestCase {
    name: "HintLogic"

    function test_shortcutFormattingUsesReadableOmarchyNames() {
        compare(HintLogic.displayShortcut("SUPER ALT + SPACE"), "Super Alt + Space");
        compare(HintLogic.displayShortcut("ALT + TAB"), "Alt + Tab");
        compare(HintLogic.displayShortcut("SUPER + RETURN"), "Super + Enter");
        compare(HintLogic.displayShortcut("SUPER SHIFT CTRL + D"), "Super Shift Ctrl + D");
    }

    function test_catalogParserKeepsFirstMatchingOmarchyBinding() {
        const shortcuts = HintLogic.parseShortcuts("SUPER CTRL ALT + D → Calendar\nSUPER SHIFT + C → Calendar\nSUPER ALT + SPACE → Apps menu\n");
        compare(shortcuts["Calendar"], "Super Ctrl Alt + D");
        compare(shortcuts["Apps menu"], "Super Alt + Space");
    }

    function test_shortcutIsOnlyShownWhenItExists() {
        compare(HintLogic.withShortcut("Open weather", "Super Ctrl Alt + W"), "Open weather (Super Ctrl Alt + W)");
        compare(HintLogic.withShortcut("Open weather", ""), "Open weather");
    }

    function test_pinnedApplicationHintLeavesActionsToItsMenu() {
        compare(HintLogic.application("Cliamp", ""), "Cliamp");
        compare(HintLogic.application("Terminal", "Super + Enter"), "Terminal (Super + Enter)");
    }

    function test_startIndicatorsUseOmarchyStateActions() {
        compare(HintLogic.startIndicator("ScreenRecording", false), "Screen Recording");
        compare(HintLogic.startIndicator("ScreenRecording", true), "Stop recording");
        compare(HintLogic.startIndicator("StayAwake", false), "Stay Awake");
        compare(HintLogic.startIndicator("StayAwake", true), "Allow Idle Lock & Screensaver");
        compare(HintLogic.startIndicator("CustomIndicator", false), "Custom Indicator");
    }

    function test_taskHintDoesNotExplainStandardWindowBehavior() {
        compare(HintLogic.task("Editor"), "Editor");
    }

    function test_pinnedHintReportsRunningStateAndWindowCount() {
        compare(HintLogic.pinnedApplication("Cliamp", "", "none", 0), "Cliamp");
        compare(HintLogic.pinnedApplication("Cliamp", "Super + Enter", "running", 1), "Cliamp (Super + Enter)");
        compare(HintLogic.pinnedApplication("Cliamp", "", "running", 3), "Cliamp, 3 windows");
        compare(HintLogic.pinnedApplication("Cliamp", "", "focused", 1), "Cliamp, focused");
        compare(HintLogic.pinnedApplication("Cliamp", "", "urgent", 4), "Cliamp, needs attention");
        compare(HintLogic.pinnedApplication("Cliamp", "", "minimized", 1), "Cliamp, minimized");
        compare(HintLogic.pinnedApplication("Cliamp", "", "minimized", 2), "Cliamp, 2 minimized windows");
    }

    function test_trayHintDoesNotExplainStandardPointerBehavior() {
        compare(HintLogic.tray("Dropbox"), "Dropbox");
        compare(HintLogic.tray("Updates"), "Updates");
    }

    function test_workspaceHintExpandsTheNumberShortcutFamily() {
        compare(HintLogic.workspace("Super + 1"), "Switch workspace (Super + 1, 2, …)");
        compare(HintLogic.workspace(""), "Switch workspace");
    }
}

import QtQuick
import QtTest
import "../../qml/models"
import "../../qml/BarGeometry.js" as BarGeometry

TestCase {
    id: testCase

    name: "TaskModel"
    when: windowShown

    ListModel {
        id: windows
    }

    QtObject {
        id: catalog

        property string iconName: "application"
        property var overrideIds: ({})

        function identityFor(record) {
            const desktopId = overrideIds[record.appId] !== undefined ? overrideIds[record.appId] : record.appId;
            return {
                desktopId: desktopId,
                name: record.appId,
                icon: iconName
            };
        }
    }

    QtObject {
        id: pinned

        property var pins: []
        property int revision: 0

        function isPinnedNormalized(desktopId) {
            const key = String(desktopId || "").trim().toLowerCase().replace(/\.desktop$/, "");
            if (key === "")
                return false;
            return pins.some(function (pin) {
                return String(pin || "").trim().toLowerCase().replace(/\.desktop$/, "") === key;
            });
        }
    }

    TaskModel {
        id: tasks

        sourceModel: windows
        sourceRevision: 0
        applicationCatalog: catalog
        applicationRevision: 0
        pinnedApplications: pinned
    }

    Flickable {
        id: viewport

        width: 100
        height: 32
        contentWidth: taskRow.implicitWidth
        onContentWidthChanged: contentX = BarGeometry.taskScrollOffset(contentX, 0, contentWidth, width)

        Row {
            id: taskRow

            Repeater {
                id: buttons

                model: tasks.model

                delegate: Item {
                    required property string address
                    required property string title
                    required property string iconName
                    required property bool minimized
                    required property bool maximized

                    width: 80
                    height: 32
                }
            }
        }
    }

    SignalSpy {
        id: removed

        target: buttons
        signalName: "itemRemoved"
    }

    SignalSpy {
        id: added

        target: buttons
        signalName: "itemAdded"
    }

    function windowRecord(address, order, appId) {
        return {
            address: address,
            title: "Window " + order,
            appId: appId || "example",
            active: false,
            urgent: false,
            minimized: false,
            fullscreen: false,
            maximized: false,
            floating: false,
            orderKey: order
        };
    }

    function addresses() {
        const result = [];
        for (let index = 0; index < buttons.count; index++)
            result.push(buttons.itemAt(index).address);
        return result.join(",");
    }

    function init() {
        windows.clear();
        catalog.iconName = "application";
        catalog.overrideIds = ({});
        pinned.pins = [];
        pinned.revision++;
        windows.append(windowRecord("0xa", 1));
        windows.append(windowRecord("0xb", 2));
        windows.append(windowRecord("0xc", 3));
        tasks.sourceRevision++;
        tryCompare(buttons, "count", 3);
        removed.clear();
        added.clear();
    }

    function cleanup() {
        windows.clear();
        pinned.pins = [];
        pinned.revision++;
        tasks.sourceRevision++;
    }

    function test_stateAndMetadataUpdatesKeepButtonsInOpeningOrder() {
        const original = [buttons.itemAt(0), buttons.itemAt(1), buttons.itemAt(2)];
        tryCompare(viewport, "contentWidth", 240);
        viewport.contentX = 80;
        for (const change of [
            {
                minimized: true
            },
            {
                minimized: false,
                active: true
            },
            {
                maximized: true
            },
            {
                maximized: false
            },
            {
                title: "Renamed",
                urgent: true
            }
        ]) {
            windows.set(0, change);
            tasks.sourceRevision++;
            compare(addresses(), "0xa,0xb,0xc");
            for (let index = 0; index < original.length; index++)
                compare(buttons.itemAt(index), original[index]);
            for (const role in change) {
                compare(tasks.model.get(0)[role], change[role]);
            }
            compare(viewport.contentX, 80);
        }
        catalog.iconName = "resolved-icon";
        tasks.applicationRevision++;
        compare(buttons.itemAt(0).iconName, "resolved-icon");
        compare(buttons.itemAt(0).title, "Renamed");
        compare(viewport.contentX, 80);
        compare(removed.count, 0);
        compare(added.count, 0);
    }

    function test_sourceReorderingDoesNotChangeTaskOrder() {
        const first = buttons.itemAt(0);
        windows.move(2, 0, 1);
        tasks.sourceRevision++;
        compare(addresses(), "0xa,0xb,0xc");
        compare(buttons.itemAt(0), first);
        compare(removed.count, 0);
        compare(added.count, 0);
    }

    function test_newWindowsAppendAndClosingPreservesSurvivors() {
        const first = buttons.itemAt(0);
        const third = buttons.itemAt(2);
        windows.insert(0, windowRecord("0xd", 4));
        tasks.sourceRevision++;
        compare(addresses(), "0xa,0xb,0xc,0xd");
        compare(added.count, 1);
        compare(removed.count, 0);

        windows.remove(2);
        tasks.sourceRevision++;
        compare(addresses(), "0xa,0xc,0xd");
        compare(buttons.itemAt(0), first);
        compare(buttons.itemAt(1), third);
        compare(removed.count, 1);
        compare(added.count, 1);

        windows.append(windowRecord("0xb", 5));
        tasks.sourceRevision++;
        compare(addresses(), "0xa,0xc,0xd,0xb");
    }

    function test_pinnedAppTasksAreCollapsed() {
        windows.set(1, windowRecord("0xb", 2, "zen"));
        pinned.pins = ["zen"];
        pinned.revision++;
        compare(addresses(), "0xa,0xc");
        compare(removed.count, 1);
    }

    // The stored pin carries no .desktop suffix here, which is the real shape.
    function test_pinChangeRebuildsRowsWithoutReplacingSurvivors() {
        windows.set(1, windowRecord("0xb", 2, "zen"));
        tasks.sourceRevision++;
        compare(addresses(), "0xa,0xb,0xc");
        // Replacing a source row replaces its own delegate, so capture the
        // survivors after that settles.
        const first = buttons.itemAt(0);
        const third = buttons.itemAt(2);
        viewport.contentX = 80;
        removed.clear();
        added.clear();

        pinned.pins = ["zen"];
        pinned.revision++;
        compare(addresses(), "0xa,0xc");
        // Collapsing mid-list must reuse the buttons that survived it.
        compare(buttons.itemAt(0), first);
        compare(buttons.itemAt(1), third);
        compare(removed.count, 1);
        compare(added.count, 0);

        pinned.pins = [];
        pinned.revision++;
        compare(addresses(), "0xa,0xb,0xc");
        compare(buttons.itemAt(0), first);
        compare(buttons.itemAt(2), third);
        compare(added.count, 1);
    }

    function test_everyWindowOfAPinnedAppIsCollapsed() {
        windows.set(0, windowRecord("0xa", 1, "zen"));
        windows.set(2, windowRecord("0xc", 3, "zen"));
        pinned.pins = ["zen"];
        pinned.revision++;
        compare(addresses(), "0xb");
    }

    function test_unresolvedIdentityStaysVisibleUnderAnyPin() {
        windows.set(0, windowRecord("0xa", 1, ""));
        windows.set(2, windowRecord("0xc", 3, ""));
        pinned.pins = ["zen", "", "  "];
        pinned.revision++;
        compare(addresses(), "0xa,0xb,0xc");
    }

    function test_normalizedPinMatchesSuffixedWindowIdentity() {
        windows.set(1, windowRecord("0xb", 2, "ZEN.desktop"));
        pinned.pins = ["zen"];
        pinned.revision++;
        compare(addresses(), "0xa,0xc");
        pinned.pins = ["zephyr"];
        pinned.revision++;
        compare(addresses(), "0xa,0xb,0xc");
    }

    function test_collapsedRowsReturnWhenTheWindowCloses() {
        windows.set(1, windowRecord("0xb", 2, "zen"));
        pinned.pins = ["zen"];
        pinned.revision++;
        compare(addresses(), "0xa,0xc");
        windows.remove(1);
        tasks.sourceRevision++;
        compare(addresses(), "0xa,0xc");
        pinned.pins = [];
        pinned.revision++;
        compare(addresses(), "0xa,0xc");
    }
}

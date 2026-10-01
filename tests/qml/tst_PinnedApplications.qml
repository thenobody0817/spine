import QtQuick
import QtTest
import "../../qml/models"

TestCase {
    id: testCase

    name: "PinnedApplications"
    when: windowShown

    QtObject {
        id: store

        property var values: ({
                "tilelanePins": ["OpenChamber", "zen"]
            })
        property bool loaded: true
        property string lastError: ""

        function setValue(key, value) {
            const next = {};
            for (const name in values)
                next[name] = values[name];
            next[key] = value;
            values = next;
            return true;
        }
    }

    PinnedApplications {
        id: pins

        settings: store
        settingsKey: "tilelanePins"
    }

    function init() {
        // The absent-settings case nulls the model, so restore both inputs here
        // rather than relying on test order.
        pins.settings = store;
        store.values = ({
                "tilelanePins": ["OpenChamber", "zen"]
            });
        compare(pins.pins.length, 2);
    }

    // These are the pin strings this machine actually stores, and they carry no
    // .desktop suffix. Exact matching would silently stop collapsing.
    function test_normalizedLookupMatchesStoredPinsWithoutSuffix() {
        verify(pins.isPinnedNormalized("OpenChamber"));
        verify(pins.isPinnedNormalized("zen"));
        verify(pins.isPinnedNormalized("zen.desktop"));
        verify(pins.isPinnedNormalized("ZEN.DESKTOP"));
        verify(pins.isPinnedNormalized("  openchamber.desktop  "));
    }

    function test_normalizedLookupRejectsOtherAndEmptyIdentities() {
        verify(!pins.isPinnedNormalized("zephyr"));
        verify(!pins.isPinnedNormalized("OpenChamber2"));
        verify(!pins.isPinnedNormalized(""));
        verify(!pins.isPinnedNormalized(null));
        verify(!pins.isPinnedNormalized("   "));
    }

    // Exact isPinned() still governs pin editing. Both lookups must keep working,
    // so unpinning and re-pinning the stored "zen" stays a valid round trip.
    function test_exactLookupIsUnchangedAndDrivesEditing() {
        verify(pins.isPinned("zen"));
        verify(!pins.isPinned("zen.desktop"));
        verify(pins.unpin("zen"));
        verify(!pins.isPinnedNormalized("zen"));
        verify(pins.pin("zen"));
        verify(pins.isPinnedNormalized("zen"));
        verify(pins.unpin("zen"));
        verify(!pins.isPinnedNormalized("zen"));
        verify(pins.pin("zen.desktop"));
        verify(pins.isPinnedNormalized("zen"));
        verify(pins.pins.join(",") === "OpenChamber,zen.desktop");
        verify(pins.move("zen.desktop", -1));
        verify(pins.pins.join(",") === "zen.desktop,OpenChamber");
        verify(pins.move("zen.desktop", -1) === false);
        verify(pins.unpin("zen.desktop"));
        verify(pins.pins.join(",") === "OpenChamber");
    }

    function test_missingSettingsModelIsUsable() {
        pins.settings = null;
        compare(pins.pins.length, 0);
        verify(!pins.isPinnedNormalized("zen"));
        verify(pins.pin("zen") === false);
    }
}

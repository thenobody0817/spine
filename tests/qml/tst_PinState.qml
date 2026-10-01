import "../../qml/AppIdentity.js" as AppIdentity
import "../../qml/PinState.js" as PinState
import QtTest

TestCase {
    name: "PinState"

    // The user's stored pins carry no .desktop suffix, so both sides have to be
    // folded the same way before an exact comparison is meaningful.
    function matches(pin) {
        const key = AppIdentity.normalized(pin);
        return function (candidate) {
            return key !== "" && key === AppIdentity.normalized(candidate);
        };
    }

    function task(address, desktopId, overrides) {
        const base = {
            address: address,
            title: "Window " + address,
            desktopId: desktopId,
            active: false,
            urgent: false,
            minimized: false,
            orderKey: 1
        };
        for (const role in overrides)
            base[role] = overrides[role];
        return base;
    }

    function test_normalizedMatchingAcceptsSuffixCaseAndSpacing() {
        const records = [task("0x1", "zen.desktop"), task("0x2", "ZEN.DESKTOP"), task("0x3", " zen.desktop ")];
        verify(AppIdentity.normalized("zen.desktop") === AppIdentity.normalized(" Zen.Desktop "));
        const suffix = PinState.forPin(records, "zen", matches("zen"));
        compare(suffix.count, 3);
        const stored = PinState.forPin(records, "zen.desktop", matches("zen.desktop"));
        compare(stored.count, 3);
    }

    function test_unmatchedAndEmptyIdentitiesStayOut() {
        const records = [task("0x1", "zen"), task("0x2", ""), task("0x3", "  "), task("0x4", "zephyr")];
        compare(PinState.forPin(records, "zen", matches("zen")).count, 1);
        compare(PinState.forPin(records, "zen", matches("")).count, 0);
        compare(PinState.forPin(records, "", matches("zen")).count, 0);
        compare(PinState.forPin([], "zen", matches("zen")).count, 0);
    }

    function test_multiWindowAggregationAndOrdering() {
        const records = [task("0x1", "zen", {
                orderKey: 2
            }), task("0x2", "zen", {
                orderKey: 7,
                urgent: true
            }), task("0x3", "zen", {
                orderKey: 5,
                active: true
            }), task("0x4", "other", {
                orderKey: 9,
                active: true
            })];
        const state = PinState.forPin(records, "zen", matches("zen"));
        compare(state.count, 3);
        verify(state.urgent);
        verify(state.active);
        verify(!state.anyMinimized);
        // Highest creation order first, matching the task list's ordering rule.
        compare(state.windows.map(function (window) {
            return window.address;
        }).join(","), "0x2,0x3,0x1");
        compare(state.windows[0].title, "Window 0x2");
    }

    function test_equalOrderKeysUseAStableAddressTiebreak() {
        const records = [task("0xa", "zen"), task("0xb", "zen"), task("0xc", "zen")];
        const state = PinState.forPin(records, "zen", matches("zen"));
        compare(state.windows.map(function (window) {
            return window.address;
        }).join(","), "0xc,0xb,0xa");
    }

    function test_indicatorPrecedenceIsUrgentThenFocusedThenMinimized() {
        const base = [task("0x1", "zen", {
                active: true
            }), task("0x2", "zen", {
                urgent: true
            }), task("0x3", "zen", {
                minimized: true
            })];
        compare(PinState.indicator(PinState.empty("zen")), "none");
        compare(PinState.indicator({
            "count": 0
        }), "none");
        compare(PinState.indicator(PinState.forPin(base, "zen", matches("zen"))), "urgent");
        compare(PinState.indicator(PinState.forPin([task("0x1", "zen", {
                active: true
            }), task("0x2", "zen", {
                minimized: true
            })], "zen", matches("zen"))), "focused");
        // One hidden window beside a visible one still reads as running. The dimmed
        // state is reserved for a pin whose windows are all hidden.
        compare(PinState.indicator(PinState.forPin([task("0x1", "zen", {
                minimized: true
            }), task("0x2", "zen")], "zen", matches("zen"))), "running");
        compare(PinState.indicator(PinState.forPin([task("0x1", "zen", {
                minimized: true
            })], "zen", matches("zen"))), "minimized");
        compare(PinState.indicator(PinState.forPin([task("0x1", "zen")], "zen", matches("zen"))), "running");
    }

    function test_minimizeAggregationSeparatesAnyFromAll() {
        const mixed = PinState.forPin([task("0x1", "zen", {
                minimized: true
            }), task("0x2", "zen")], "zen", matches("zen"));
        verify(mixed.anyMinimized);
        verify(!mixed.allMinimized);
        const single = PinState.forPin([task("0x1", "zen", {
                minimized: true
            })], "zen", matches("zen"));
        verify(single.anyMinimized);
        verify(single.allMinimized);
        const none = PinState.forPin([task("0x1", "zen")], "zen", matches("zen"));
        verify(!none.anyMinimized);
        verify(!none.allMinimized);
        verify(!PinState.empty("zen").allMinimized);
    }

    function test_missingPredicateMatchesNothing() {
        compare(PinState.forPin([task("0x1", "zen")], "zen", null).count, 0);
    }

    function test_windowStateLabelReflectsTheStrongestState() {
        compare(PinState.windowStateLabel(null), "");
        compare(PinState.windowStateLabel({
            "urgent": true,
            "active": true
        }), "Urgent");
        compare(PinState.windowStateLabel({
            "active": true
        }), "Active");
        compare(PinState.windowStateLabel({
            "minimized": true
        }), "Minimized");
        compare(PinState.windowStateLabel({}), "");
    }
}

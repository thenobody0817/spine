# Behavior and test coverage

This table describes current behavior. Automated checks are in `scripts/check`.
Older measurements are in [performance.md](performance.md). A past live check is not a fresh result
for every later change.

| Area              | Current behavior                                                                                                                | Evidence or limit                                                                                          |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Loading           | Omarchy loads one full-bar root into its existing shell.                                                                        | Manifest validation and live smoke pass.                                                                   |
| Screens           | Each screen gets a bottom bar, Start, workspace control, and tasks.                                                             | Earlier virtual hot-plug checks passed. Physical cable tests remain open.                                  |
| Status group      | Tray, native controls, and clock are visible on the first Quickshell screen.                                                    | Other screen bars do not show this group.                                                                  |
| Height            | Base height is 44 logical pixels, adjusted by Omarchy spacing and font scale.                                                   | Geometry tests cover four scales.                                                                          |
| Window list       | Each window has its own task. Tasks include all workspaces on the monitor.                                                      | Model and duplicate-app tests pass.                                                                        |
| Order             | Hyprland's creation ID defines task order. Missing details use a temporary order.                                               | Reload, focus, minimize, and model-order tests pass.                                                       |
| Row updates       | Existing task rows update in place.                                                                                             | Tests check delegate identity and scroll position.                                                         |
| Focus             | Clicking an inactive task selects its workspace and exact window.                                                               | Pointer tests check restoration of cursor-warp settings.                                                   |
| Minimize          | Clicking an active task moves it to a private special workspace.                                                                | A journal stores its original workspace. Lifecycle tests cover the move race.                              |
| Restore           | A minimized task returns to its saved workspace and keeps tiled or floating mode.                                               | Controlled live tiled and floating cycles passed.                                                          |
| Task menu         | Right-click opens actions for that exact window.                                                                                | Actions reject stale or invalid targets.                                                                   |
| App identity      | A task uses desktop metadata, overrides, and bounded terminal or web-app matching.                                              | Cliamp and ambiguous identity fixtures pass.                                                               |
| Taskbar pins      | Pins stay outside the scrolling task list. Their menu can reorder them.                                                         | Pin and overflow checks pass.                                                                              |
| Collapsed pins    | A pinned app that is running shows an underline on its pin instead of its own task buttons.                                    | Matching, aggregation, and collapse tests pass. Confirmed live for one and two windows.                     |
| Pin window picker | A pinned app with several windows lists them in its menu. Selecting one focuses it.                                            | Menu structure verified live with two windows. Per-window minimize, restore, and close need a pointer check. |
| Start pins        | Start has separate pins. Changed order applies on the next opening.                                                             | Start-order tests pass.                                                                                    |
| Settings          | Pins and preferences use inline fields in Omarchy's `shell.json`. Old preferences are imported once.                            | Tests cover fresh setup, independent pins, restart, external edits, invalid data, and inactive-bar writes. |
| Launch            | Normal launch uses `uwsm-app -- gtk-launch`.                                                                                    | The helper test checks quoting and floating launch behavior.                                               |
| Floating launch   | Ctrl+Click, Ctrl+Enter in Start, and Open floating request a floating window.                                                   | Follow-up client checks are bounded.                                                                       |
| Task overflow     | Matching chevrons scroll tasks. Partly hidden tasks fade near the edge.                                                         | Geometry checks cover scroll bounds.                                                                       |
| Bottom edge       | Taskbar controls accept clicks below their visible frame. Start and clock reach their outer screen edges.                       | Click-area tests and live edge clicks pass.                                                                |
| Workspaces        | The numbered button opens a fan after a 200 ms hover or on click.                                                               | Workspace tests cover state and selection.                                                                 |
| Start search      | Search filters a cached, Omarchy-filtered app index.                                                                            | Search, selection, and hidden-entry checks pass.                                                           |
| Places            | Start shows standard Files locations and updates GTK bookmarks when they change.                                                | Parsing tests and file-watcher tests cover removal, rename, replacement, empty files, and legacy fallback. |
| Tray              | Left activates, right opens a menu, middle requests secondary activation, and wheel input forwards to the item.                 | Live D-Bus menu and edge-click checks passed.                                                              |
| Tray reveal       | Hover waits 200 ms. The drawer width is capped and can scroll.                                                                  | Live delayed bottom-edge hover passed.                                                                     |
| Audio right-click | Toggles output mute without opening the mixer.                                                                                  | Controlled live mute checks passed.                                                                        |
| Native panels     | Configured widgets load dynamically in layout order. Known panel-only controls load on demand.                                  | Tests cover add/remove, reorder without reloading, settings, native input, and manifest loading.           |
| Panel shortcuts   | Named shortcuts use shell open/close hooks. Numbers count visible panels.                                                       | Four named routes and eight visible numbered routes passed live checks.                                    |
| Clock             | The label updates by minute. Its open indicator matches the text width.                                                         | The final visible status control receives right-edge padding.                                              |
| Appearance        | Colors and text use Omarchy roles. Start and native menu containers use Omarchy rounding.                                       | Manual checks cover recent changes. A current visual baseline remains open.                                |
| Focus             | Pointer clicks do not force keyboard focus on the guarded bar controls.                                                         | Shared-control tests verify pointer clicks, keyboard focus, dismissal, and secondary actions.              |
| Reduced motion    | Tilelane sets owned animation durations to zero and stops launch pulses.                                                        | Geometry tests cover the duration switch.                                                                  |
| Missing data      | Optional missing entries do not supply a usable panel. Invalid inline fields use safe defaults without overwriting stored data. | Removal, validation, and settings persistence tests cover these cases.                                     |
| Recovery          | Normal unload queues restores. A new instance can read the saved minimize journal.                                              | Earlier reset and hard-restart checks passed.                                                              |

## Checks that remain open

Battery power comparisons, physical cable hot-plug, and suspend/resume need
hardware testing. Urgent state has fixture coverage, but a live bell did not
produce a compositor urgency event in the earlier terminal test.

The second monitor was not available when the collapsed-pin feature was
checked, so that path rests on tests alone. Click-cycling through an app's
windows was read from the diagnostic state rather than clicked. Clicking a
pinned app's own per-window minimize, restore, and close buttons in the picker
still needs a live pointer check.

The image fixtures do not contain matching full Start and tray scenes for
both light and dark themes. They cannot establish pixel identity for the
current UI. See [visual notes](visual-parity.md).

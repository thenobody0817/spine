# Architecture

This document describes the current code. Historical measurements are in
[performance.md](performance.md).

## Omarchy integration

The root manifest declares schema version 1, kind `bar`, and entry point
`Bar.qml`. The root is a QML `Item`. Omarchy loads it into the existing shell.
Spine creates one bottom `PanelWindow` for each Quickshell screen.

The root accepts `omarchyPath`, `shell`, `manifest`, `pluginRegistry`,
`barWidgetRegistry`, and `barConfig`. Omarchy supplies restricted interfaces
and detached configuration snapshots to third-party plugins. Spine uses
those interfaces for configured widgets and non-authentication menus.

The host selects the full bar through `bar.id` in `shell.json`.
`omarchy bar use io.github.thenobody0817.spine` selects Spine. `omarchy bar reset` selects
the built-in bar. Omarchy handles missing or invalid bar entries and load failures.

Spine is a fork of `lexeko/tilelane` and installs under its own plugin id, so
upstream Tilelane and this fork can both be installed at once. The plugin id is
the directory name under `~/.config/omarchy/plugins/` and must match `bar.id`.
`TilelaneSettings.qml` gates every read and write on that match, so changing one
side without the other leaves the bar inert with no visible error. Runtime
strings keep their upstream `tilelane` spelling on purpose: the IPC target, the
layer-shell namespaces, the `tilelane*` fields in `shell.json`, the
`special:tilelane-minimized` workspace, and its minimize journal. Those names
address existing user data, and minimized windows would be stranded if the fork
renamed them without migrating the journal.
This fallback does not guarantee recovery from every runtime error.

The contract comes from the installed `shell/README.md`, `shell.qml`, and
`services/PluginRegistry.qml` under `/usr/share/omarchy`.
Those packaged files are read-only references for this project.

Spine was tested on two computers, with single-monitor and multi-monitor
setups running Omarchy 4.0.4, Hyprland 0.56.2, and Qt 6.11.2. Testing included
manual checks and automated regression tests. The current checks passed 187
QML test cases, along with integration and rendering tests.
Window-model integration tests exercise the production model.

## Shared models and screen views

`Bar.qml` owns one `WindowModel`, `WorkspaceModel`, `ApplicationCatalog`,
`WindowActions`, `ShortcutCatalog`, and `TilelaneSettings`. Two `PinnedApplications`
models keep Start and taskbar pins separate.

Each screen has a window filter, task model, Start menu, workspace control,
status group, and tooltip window. Hosted widgets follow their own loading rules.

Start briefly acquires exclusive keyboard focus when opening, then uses
on-demand focus so other monitors can receive pointer events. Transparent
dismissal surfaces on the other screens close Start on an outside press
without taking keyboard focus. Closing removes those surfaces and clears the
menu's input region immediately, even while its visual fade-out continues.
After acquiring focus, Start also closes immediately when its window loses
focus to another interface or Hyprland reports a newly opened application
window. The latter covers applications that map behind the focused layer.
These handoffs skip the closing animation. Quick toggles remain visible, and
moving focus between Start's controls does not dismiss it. This behavior does
not depend on indicator IDs or commands. A background application opening a
window also dismisses Start.

`WindowFilter.qml` includes all workspaces on the matching monitor.
A synthetic `FALLBACK` screen can show the global window list.
The base bar height is 44 logical pixels. Omarchy's spacing and font scale
can change it. Output pixel density affects image resolution, not layout twice.

## Window state and ordering

`WindowModel.qml` tracks `Hyprland.toplevels` and their property signals.
It stores normalized records in one `ListModel`. A generation value rejects
stale close events. Equal records do not advance the model revision.

Window opening order comes from Hyprland's `stableId` creation counter.
A window without that detail gets a temporary increasing order value.
When the detail arrives, the model can correct that window's position.
Focus, title, and minimize changes do not define task order.

`TaskModel.qml` creates one row per window, except windows whose resolved
desktop entry is pinned. It updates existing rows in place. This preserves button
instances and the task list's scroll position. Pins sit outside the scrolling
list. Task overflow fades cover 24 scaled pixels.

A pin's running state comes from the shared, unfiltered `WindowModel`, not from
a monitor's filtered `TaskModel`. Minimizing a window moves it to
`special:tilelane-minimized`, where it no longer matches its monitor, so a
filtered model would drop the pin's running state at that moment. `WindowModel.records()`
supplies plain copies for this purpose. Each screen keeps its own `TaskModel`
and `TaskLane`; they all read the one shared window model.

A new window without a PID can request one batched toplevel refresh after
50 ms. This uses Quickshell's Hyprland API. It is not a recurring refresh loop.

## Window actions and recovery

`WindowActions.qml` validates an exact window address before acting.
Activation and restore normally use `Hyprland.dispatch()`.
Close first tries the Wayland handle. Other actions and fallback paths use
one detached `hyprctl eval` command.

The tested Hyprland release ignored the Wayland toplevel's minimized setter.
Spine therefore moves minimized windows to `special:tilelane-minimized`.
The recovery journal records its original workspace before the move.
The model must observe the hidden workspace before a later normal-workspace
update can clear that record. This avoids losing the origin during an
asynchronous minimize.

Restore returns the window to its saved workspace. It does not change the
workspace layout or force floating mode. Pointer-preserving dispatches save
Hyprland's cursor-warp settings, suppress warping for the action, and restore
the settings even when the dispatch fails.

The journal uses `Quickshell.statePath("tilelane-minimized-v1.json")`.
It contains a version, window addresses, and workspace names. It contains no
titles. File writes are atomic. Normal component destruction queues restores
for tracked windows. After a hard shell failure, the next instance reads the
journal and can restore them.

## Workspace switching

Each workspace button displays the active workspace on its own monitor.
The fan highlight and initial keyboard selection use the same monitor-local
workspace. Moving focus between monitors does not change either indicator.
Workspace activity and monitor assignments come from the shared model's
Hyprland signals; a missing monitor has no active indicator.
Workspace moves can leave Quickshell's cached active workspace at an
intermediate focus event. The model coalesces move events for 25 ms, then
refreshes workspace and monitor state through Quickshell's compositor socket.
This is event-triggered and adds no polling or helper process.
With multiple screens connected, the fan hint also shows the configured
shortcuts for moving the current workspace to another monitor. This extra
hint disappears when only one screen remains.

Workspace actions use `Hyprland.dispatch()` with validated Lua commands.
The tested Quickshell workspace helper emitted an older command grammar that
Hyprland rejected. Spine accepts numbered targets from 1 through 10.
Live workspace signals confirm the resulting state.

## App identity and launch

`ApplicationCatalog.qml` reads Quickshell's desktop-entry model.
Explicit overrides take precedence. Other matches use terminal child names,
desktop IDs, startup classes, known web-app hosts, and a final heuristic lookup.
Ambiguous matches retain the terminal or browser identity.

## Pinned apps and running windows

A pinned app that is running shows its state on the pin instead of as its own
task button. `TaskModel.qml` excludes those rows and rebuilds when the pin
model's revision changes. The surviving rows keep their existing button
instances, so pinning a running app mid-list does not rebuild the others.
Filtering lives in `TaskModel` rather than `TaskLane`, which keeps the lane and
`openContextMenu()` unaware of pins. A window whose identity does not resolve
matches no pin, so it stays visible rather than hiding behind the wrong pin.

`PinState.js` turns the shared model's records into one pin's window list and
its aggregate state. It is a plain JavaScript library so it can be tested
without a compositor. A QML JavaScript library cannot import another library,
so the caller passes the desktop-entry comparison in as a predicate.

That comparison normalizes both sides through `AppIdentity.normalized()` before
comparing them exactly. Quickshell strips the `.desktop` suffix from entry
IDs, while stored pins keep whatever the user or Omarchy wrote, so `"zen"` and
`"zen.desktop"` must match. `PinnedApplications.isPinnedNormalized()` applies the
same rule. Plain `isPinned()` still uses exact strings and continues to drive
pin editing, so stored pin values are not rewritten.

The pin draws one 2px underline, matching the active-task underline in
`TaskButton.qml`. `PinState.indicator()` picks its state: urgent outranks
focused, then minimized when every one of the app's windows is hidden, otherwise
running. Focused and urgent underlines span the pin; running and minimized
underlines are shorter. Urgent uses `Commons.Color.urgent` and minimized dims
the accent. The underline supersedes the underline that marks an open menu, so
the two never stack. A count badge appears when the app has more than one window.

Left-click on a running pin behaves like its task button: it restores a
minimized window, minimizes the focused one, and otherwise activates it, reusing
`WindowActions.toggle()`. With several windows it focuses the most recent one and
cycles through the app's windows on later clicks. Ctrl+Click still requests a
floating launch. Launching another instance moves to the menu's Open item.

The pin's right-click menu lists the app's windows above the existing pin items
when it has more than one. Selecting a row focuses that window, restoring it if
it is minimized. Each row carries minimize or restore and close as secondary
pointer actions beside the title.

Terminal windows group as expected. `AppIdentity.terminalEntry()` maps a
terminal-hosted window to the terminal's own desktop entry, so pinning a
terminal collapses all of its windows under that one pin. This is the same
grouping the Start menu and task list already use.

The identity helper checks whether a new window's process owns a terminal.
It walks at most 128 descendant processes and reports executable names.
It does not read command arguments. The first probe waits 250 ms.
A late terminal can get one recheck. Confirmed terminal hosts can receive up
to three retries at 350 ms intervals. Probing then stops.

The catalog filters hidden desktop entries before building the Start index.
It reads Omarchy's launcher hide list and freedesktop visibility fields.
Opening Start filters the cached index. It does not rescan desktop files.
Start snapshots its pin order for that opening.

Normal launch uses `uwsm-app -- gtk-launch` with a resolved desktop-file ID.
Floating launch uses the same command through Hyprland's per-launch float
option. The helper quotes the ID for both shell and Lua syntax. It does not
copy or rewrite a desktop file's `Exec` field.

A floating launch can check for a new matching window up to 40 times.
There is a 100 ms wait between unsuccessful checks. This is bounded polling
after a user action. It is not idle polling, and the total time also includes
command execution. No permanent window rule is installed.

## Tray and native panels

`TrayIcon.qml` tints neutral pixels in symbolic application icons. It preserves
colored badges with the shader in `qml/shaders`. Full-color icons and native
Omarchy controls keep their existing rendering. The shader source and build
instructions ship with its compiled file.

`TrayArea.qml` uses Quickshell's StatusNotifier model. Left-click activates
an item or opens its menu when the item is menu-only. Right-click opens its
context menu. Middle-click requests secondary activation. Wheel input goes
to the tray item.

The tray opens after a 200 ms hover delay and collapses after a 120 ms delay.
Its drawer width is capped at 300 scaled pixels, or 120 in compact mode.
Compact mode starts below 900 scaled logical pixels.

`StatusWidgetModel.qml` joins configured widgets into the right-hand status
area. From left to right, it places the left/right section controls, the center
section's information widgets, and the clock in separate groups. It preserves
configured item order within each group and keeps the clock at the right edge.
Spacing follows these display groups rather than the source sections.
It includes only entries present in the injected `barWidgetRegistry`. The
standard menu, workspace, and indicator entries are excluded because Spine
supplies those surfaces itself. A registry entry alone does not add an icon;
the widget must also be configured in the layout. Settings merge registry
defaults with that entry's inline values.

Model rows use stable widget/occurrence keys. Reordering moves existing rows;
settings edits update them in place. Removing a layout entry or disabling its
plugin destroys its slot. Each screen owns its own status widgets and tray
drawer, created and destroyed with its bar surface. Tray entries share
Quickshell's system tray service; native widget panels anchor to their local
control. Named panel shortcuts close an existing panel first, otherwise they
open on the focused screen. Numbered shortcuts count visible panels only on
that screen, in visual order.
Multiple instances are allowed only when the registry metadata permits them.

`StartIndicators.qml` keeps Start's indicators in configured order regardless
of active state. It reads `items` (or the legacy `indicators` list) from the
indicator widget's settings. An empty selection uses the ordered choices in
the registered widget's `items` schema, matching Omarchy's all-indicators
default without duplicating the list in Spine. Stable keys retain native
instances across configuration reordering and settings edits.

The row loads Omarchy's native indicator QML files from the sibling
`indicators` directory used by Omarchy's widget, supplying the
native `single` block, settings, bar, and refresh host. Indicator IDs cannot
contain path separators or traversal. Native state, visuals, and actions stay
with those components; Spine supplies placement and Start's hints. The
`omarchy.indicators refresh` IPC broadcasts to every screen's row. This adapter
depends on Omarchy's current indicator schema, source layout, and `BarIndicator`
properties; changes to that contract require compatibility review.

`StatusWidgetSlot.qml` chooses a compact presentation for familiar widgets and
uses `NativeWidget.qml` for any other registered component. `StatusControl.qml`
owns hover/press backgrounds, keyboard activation, accessible names, hints,
and the accent underline. Application tray entries use the same control.
Hints follow the shared hover state across the full hit area, including screen
edges. Nonblocking observers on the control and tray ancestors preserve the
native mouse areas' hover events. Generic widgets use their native button's tooltip text,
falling back to the registry display name without a per-plugin label list.
Pointer clicks do not assign keyboard focus. Native components retain their
own mouse and wheel handlers; the generic host does not replace their internal
controls or promise to override styling drawn by the plugin itself.
Native visuals retain their intrinsic size when they fit the full bar height;
only taller widgets scale down proportionally. Their height includes native
button padding, so fitting them into Spine's smaller hover rectangle would
also shrink the icon. Sizing has no per-plugin overrides.

`HostedBarWidget.qml` loads widget implementations from the injected registry
and supplies `bar`, `moduleName`, and per-instance `settings`. Agents,
Bluetooth, Network, Audio, Displays, and Power load on demand and unload
250 ms after closing. Visual widgets such as the clock and Dropbox have
persistent hosts. Their own panels may have further loaders.

Hosted widget trees are observed when nested loaders and visual children change.
Status discovery reads QObject `data` lists outside property bindings and then
binds to the discovered object's status properties. URL-loaded widgets receive
their visual parent as an initial property, letting the host observe nested IPC
handlers before registration without asynchronous widget incubation.

A bar-owned `NativeIpcRegistry` allows one enabled native handler per target,
preferring the focused monitor and falling back to another live instance. It
uses reversible `Binding` overrides to preserve native enabled expressions;
native method signatures and broadcast refresh behavior stay intact. Removing
an output or reloading a widget releases ownership before another instance
registers. The bar unloads hosted widgets before its own destruction, keeping
native panel theme/geometry bindings valid during teardown. This coordination
covers hosted widgets, not the shell's own startup IPC handlers.

If a registry entry has no component, known presentations retain their fallback
entry point. For an unfamiliar widget, the host reads the declared `barWidget`
entry point from `manifest.json` under the registry's public `sourceDir`.
It watches that file and rejects absolute paths and parent traversal. This
handles an observed Omarchy 4.0.4 startup issue without assuming a filename,
scanning plugin directories, polling, or loading an absent registry entry.

Mouse actions retain their original button. Audio right-click calls
`omarchy audio output volume mute-toggle` directly, without opening the mixer.

The full bar implements `summonBarWidget`, `hideBarWidget`,
`isBarWidgetOpen`, and `panelWidgetIdAt`. A host stays registered while its
lazy panel is unloaded. Standard shell shortcuts can therefore open it before
its first mouse click. Routing prefers an open panel, then the focused output.
Numbered shortcuts count visible panels in horizontal order.

Shortcut labels come from `omarchy menu keybindings --print`. The catalog reads
them at startup and refreshes when the watched user bindings change. Labels
match existing command descriptions. Spine does not write keybindings.

`BarMouseArea.qml` extends each control's clickable area to the bottom edge.
It clips horizontal click bounds to the visible task or tray viewport.
Start also reaches the left edge. The clock reaches the right edge.
The host's panel overlay can forward clicks to these same areas.
Status hover feedback follows the extended hit area too, including native
widgets that retain their own mouse handlers. Padding comes from the current
layout, so changing widget order or size keeps edge interaction intact.

## External text

All Text items owned by Spine explicitly use `Text.PlainText`. Bookmark
labels, app names, window titles, shortcut hints, clock formats, and status
labels remain literal strings; embedded markup cannot change their formatting
or load inline images. Hosted widgets retain responsibility for their own text.
The checker renders the production bookmark label with markup-like inputs and
checks every owned Text declaration for this policy.

## Files and settings

| Path                                                 | Use                                                |
| ---------------------------------------------------- | -------------------------------------------------- |
| `Quickshell.statePath("tilelane-minimized-v1.json")` | Minimize recovery journal                          |
| Omarchy `shell.json`                                 | Active bar, widgets, Spine pins and preferences |
| `$XDG_CONFIG_HOME/tilelane/pins.json`                | Read once for legacy preferences, never written    |

`XDG_CONFIG_HOME` defaults to `~/.config`.
Spine uses inline fields on the `bar` entry: `tilelanePins`,
`tilelaneStartPins`, `tilelaneIdentityOverrides`, and `reducedMotion`.
`tilelaneSettingsVersion: 1` records initialization. The injected `barConfig`
snapshot supplies current values. Saves use the scoped
`shell.mutateShellConfig()` callback, which lets the host persist bar changes.
Spine does not write `shell.json` directly or start a process to save pins.
Each action changes only its own field and preserves other bar and shell settings.

On first use, Spine reads identity overrides and reduced motion from the
old pin file. Existing inline values take precedence. Old pins are not imported.
Once initialized, Spine no longer reads the old file. Invalid legacy
preferences block initialization and report an error rather than being discarded.
Invalid inline fields use safe defaults without rewriting the stored data.
Valid fields remain usable. An unsupported settings version blocks writes.

Start always includes Home, Recent, Starred, Network, and Trash. It adds
bookmarks from `$XDG_CONFIG_HOME/gtk-3.0/bookmarks`, the file used by Files.
Bookmark labels and order follow that file. Duplicate URIs appear once.
Spine only reads bookmarks; users manage them in Files.
It falls back to `~/.gtk-bookmarks` when the GTK 3 bookmark file is unavailable.
File watchers reload bookmark and directory files before updating the Places
model. An empty GTK bookmark file means no bookmarks; it does not trigger the
legacy fallback.

`$XDG_CONFIG_HOME/user-dirs.dirs` supplies folder paths for icons such as
Documents and Downloads. It does not add places to the list.

Branding comes from Omarchy's user config directory. The launcher hide list
comes from `$OMARCHY_PATH/default/omarchy/launcher.hides`.
The shortcut catalog watches `~/.config/hypr/bindings.lua`.

## Processes and commands

| Owner                        | Trigger and work                                                                                                        |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `WindowActions.qml`          | A window action or unload can run a validated `hyprctl eval`.                                                           |
| `WindowModel.qml`            | New windows can run `scripts/window-application-identities` with bounded retries.                                       |
| `ApplicationCatalog.qml`     | Startup and catalog changes can run `scripts/hidden-desktop-entries`.                                                   |
| `ApplicationCatalog.qml`     | App launch uses `uwsm-app`, `gtk-launch`, or `scripts/launch-application`.                                              |
| `scripts/launch-application` | Can query Ctrl state, call `xdg-terminal-exec --print-id`, dispatch a floating launch, and check new clients with `jq`. |
| `ShortcutCatalog.qml`        | Startup and a binding-file change run `omarchy menu keybindings --print`.                                               |
| `ApplicationCatalog.qml`     | Opening a place uses the launch helper to run `uwsm-app -- nautilus --new-window`. Ctrl requests floating.              |
| `PanelControl.qml`           | Audio right-click runs Omarchy's output mute command.                                                                   |
| `Bar.qml` and hosted widgets | Native widget actions can run their configured commands through `Commons.Util.execDetached`.                            |

The three runtime helper scripts require Bash and standard system utilities.
There is no installer hook, downloaded runtime code, compiled helper, privilege
request, or Spine-owned service. Hosted Omarchy widgets keep their upstream
refresh schedules and command behavior. A process-free claim would be false.

A resident helper would need a specific capability, measurements, and a
packaging review. The current implementation does not require one.

## Diagnostics

The `tilelane` IPC target returns counts, revisions, workspace placement,
control state, configured widget IDs/order, and targeted action results. It omits titles, command lines,
account data, and registry source paths. Address lookup needs a supplied PID
or app ID. Window state and actions need a supplied address.
These commands run in the user's session. They are not an authorization layer.

`pinState` is the one exception to omitting titles. It reports each pin's
window count, aggregate state, and window titles, which is how the collapsed-pinned
behavior can be checked without using the mouse. Pass a desktop ID for one pin
or an empty string for all of them. `pinCollapses` reports whether an identity
currently collapses its task buttons.

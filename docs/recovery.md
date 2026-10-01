# Recovery and diagnostics

## Select or reset the bar

Check that the shell responds and Tilelane is installed:

```sh
omarchy-shell shell ping
omarchy plugin list --json
```

Select Tilelane:

```sh
omarchy bar use io.github.lexeko.tilelane
```

Return to the built-in bar:

```sh
omarchy bar reset
```

If the shell is unhealthy, reset the bar and restart the shell:

```sh
omarchy bar reset
omarchy restart shell
```

Do not use `omarchy refresh shell` for this. That command replaces shell
configuration. `omarchy bar defaults` also resets more than the bar selection.

Omarchy can fall back to its built-in bar when a selected plugin is missing,
invalid, or fails to load. A runtime error may still need a restart.

## Reload changed plugin files

A development install must contain the QML files and runtime scripts.
Validate the installed folder, then ask Omarchy to discover changes:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/io.github.lexeko.tilelane
omarchy-shell shell rescanPlugins
```

If the old component is still visible, use `omarchy restart shell`.
Do not edit `/usr/share/omarchy` or start Tilelane in another Quickshell process.

## Check the running bar

From the repository root:

```sh
./scripts/smoke
```

This is a read-only check. It requires Tilelane to be selected already.
It checks the shell, active plugin ID, layer count, and bottom reservation.
Its default expected height is 44 logical pixels. Set
`TILELANE_EXPECTED_HEIGHT` if Omarchy's font or spacing settings change that height.

## Recover minimized windows

Tilelane moves minimized windows to `special:tilelane-minimized`.
It writes the original workspace to a journal in Quickshell's state directory.
The filename is `tilelane-minimized-v1.json`.

A normal bar reset queues restores for tracked windows before Tilelane unloads.
After a hard shell failure, select Tilelane again and click the minimized task.
The new instance reads the journal and restores the window to its saved workspace.

A missing or invalid journal cannot supply the original workspace.
Tilelane will not guess a tiled restore through the native minimized setter
for a window in its private workspace. Keep a valid journal when recovering
from a crash. Do not edit it while Tilelane is active.

## Recover pins or settings

Tilelane stores its settings on the `bar` entry in
`~/.config/omarchy/shell.json`. `XDG_CONFIG_HOME`, when set, replaces `~/.config`.
Back up this file before editing it. Keep its other fields and layout entries.

| Field on `bar`              | Value                                                 |
| --------------------------- | ----------------------------------------------------- |
| `tilelaneSettingsVersion`   | `1`                                                   |
| `tilelanePins`              | Ordered array of taskbar desktop-entry IDs            |
| `tilelaneStartPins`         | Ordered array of Start desktop-entry IDs              |
| `tilelaneIdentityOverrides` | Object mapping window identities to desktop-entry IDs |
| `reducedMotion`             | `true` or `false`                                     |

To clear pins, set the corresponding array to `[]`. A missing app remains a
removable taskbar pin.

A pinned app that is running shows an underline on its pin instead of its own
task buttons. This is not a stored setting, so there is nothing to reset for it.
To give an app its task buttons back, unpin it with its right-click menu or:

```sh
omarchy-shell tilelane pinAction zen unpin
```

Pin values are matched loosely, ignoring case and an optional `.desktop`
suffix, because Quickshell strips that suffix from desktop-entry IDs. Storing
`"zen"` or `"zen.desktop"` works the same way. Tilelane does not rewrite a
stored pin to match a running app. If a running app does not collapse, its
identity may not resolve; check `omarchy-shell tilelane identityOverrides`
settings and the app's window identity in Hyprland.

Invalid fields use safe defaults and log an error.
Tilelane leaves the invalid data on disk until you correct it or change that
setting. Other valid settings remain usable. An unsupported settings version
blocks saves.

On first use, Tilelane imports preferences from the old
`~/.config/tilelane/pins.json`. Existing inline settings take precedence.
Old taskbar and Start pins are not imported. The old files remain untouched.
After `tilelaneSettingsVersion` is set, they are no longer read.
If an invalid old preference prevents initialization, fix the old file and
restart the shell. Back it up before making changes.

Use the IPC command to change `bar.reducedMotion`:

```sh
omarchy-shell tilelane reducedMotionSet true
omarchy-shell tilelane reducedMotionState
omarchy-shell tilelane reducedMotionSet false
```

## Check places in Start

Start gets its bookmarks from Files. They are separate from Tilelane's app pins.
Changes in Files should appear automatically.

If a bookmark is missing or stale, check
`$XDG_CONFIG_HOME/gtk-3.0/bookmarks`. The default path is
`~/.config/gtk-3.0/bookmarks`. Tilelane reads `~/.gtk-bookmarks` only when that
file is unavailable. An empty GTK 3 bookmark file means no bookmarks.

Home, Recent, Starred, Network, and Trash are built-in entries. Removing
bookmarks does not remove those entries.

## Check native panels and shortcuts

Read a panel's state without opening it:

```sh
omarchy-shell tilelane hostPanelState omarchy.audio ''
```

For lazy panels, `available: false` can be normal before opening or after
closing. `hasEntry` reports whether the registry supplies the widget.
`configured`, `visible`, and `opened` are available for the standard panel controls.
The clock uses the same diagnostic fields as the other hosted widgets.

Test the same route used by Omarchy's Audio shortcut:

```sh
omarchy-shell shell toggle omarchy.audio
omarchy-shell shell hide omarchy.audio
```

These two commands change panel visibility. An unavailable or disabled widget
cannot open. After enabling or reinstalling one, rescan plugins or restart the shell.
Do not copy Omarchy's panel implementation into Tilelane.

## Read-only diagnostics

```sh
omarchy-shell tilelane windowCount
omarchy-shell tilelane revision
omarchy-shell tilelane workspaceState
omarchy-shell tilelane applicationIndexCount
omarchy-shell tilelane pinCount
omarchy-shell tilelane pinState ''
omarchy-shell tilelane startPinCount
omarchy-shell tilelane statusState ''
omarchy-shell tilelane startState ''
```

An empty screen argument selects the first registered matching view.
Use an exact monitor name from `hyprctl monitors -j` when checking a specific screen.

`windowState` takes a window address. `windowAddressForPid` and
`windowAddressForAppId` return an address for a supplied identifier.

`pinState` reports each pin's window count, whether any of its windows is
focused, urgent, or minimized, its indicator state, and its window titles. Pass a
desktop ID for one pin and an empty string for all of them. It is how to confirm
which windows a pin has collapsed without using the mouse:

```sh
omarchy-shell tilelane pinState ''
omarchy-shell tilelane pinState zen
```

`pinCollapses` answers whether an identity currently collapses its task
buttons. Diagnostics omit titles except for `pinState`, and never include
command lines, account data, or registry paths.

## Remove Tilelane

```sh
omarchy bar reset
omarchy plugin remove io.github.lexeko.tilelane
```

Removal deletes the installed plugin. Tilelane's fields remain on `bar` in
`shell.json`, ready for a later install. To clear them, back up `shell.json` and
remove `tilelaneSettingsVersion`, `tilelanePins`, `tilelaneStartPins`, and
`tilelaneIdentityOverrides`. Keep shared fields such as `layout` and `reducedMotion`.
Old files under `~/.config/tilelane/` also remain. Archive them before reinstalling
if you do not want their preferences imported again.
Restore minimized windows before removing recovery data.

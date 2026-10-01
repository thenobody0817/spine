# Tilelane

A familiar taskbar and Start menu for Omarchy. Open your apps with the mouse,
then learn Omarchy's window shortcuts from the task context menus as you go.
Use the menu today and try a shortcut next time.

Find apps in Start and pin your favorites there or on the taskbar. Each has its
own pins. Start also has Places for your folders. It picks up your bookmarks
from Files, alongside Home, Recent, and other built-in locations. Change a
bookmark in Files, and Start updates automatically.

See one task for each window, in opening order, except that a pinned app shows
its running state on the pin instead. Minimize and restore windows
without changing their tiled or floating mode. Each monitor gets a bar with
its own tasks and workspaces, plus tray icons and your configured Omarchy widgets.

Tilelane follows your Omarchy theme and leaves Hyprland in charge of tiling.
The standard shortcuts keep working. Pick a new theme, and the bar changes with it.

![Tilelane on Omarchy with the Start menu open](preview.png)

## Requirements

Tested on Omarchy 4.0.4 with Hyprland 0.56.2 and Qt 6.11.2.
Tilelane runs inside Omarchy's shell and uses its theme and fonts.

Runtime commands include Bash, `hyprctl`, `uwsm-app`, `gtk-launch`, and common
shell utilities. Floating-launch recovery also uses `jq` when available.
Start opens folders with Nautilus. Hosted Omarchy widgets keep their own dependencies.
See the full [command inventory](docs/architecture.md#processes-and-commands).

## Install

Install from GitHub and select Tilelane:

```sh
omarchy plugin add https://github.com/lexeko/tilelane.git
omarchy bar use io.github.lexeko.tilelane
```

### Manual installation

Place a complete copy in `~/.config/omarchy/plugins/io.github.lexeko.tilelane`.
Include `manifest.json`, `Bar.qml`, `qml/`, and `scripts/`.
Keep the scripts' executable permissions. Do not use a symlink.
Back up an existing installation before replacing it.

Then discover and select Tilelane:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/io.github.lexeko.tilelane
omarchy-shell shell rescanPlugins
omarchy bar use io.github.lexeko.tilelane
```

## Turn it on or off

Select Tilelane:

```sh
omarchy bar use io.github.lexeko.tilelane
```

Return to Omarchy's built-in bar:

```sh
omarchy bar reset
```

## Use the taskbar

- Click an inactive task to focus its window. Click an active task to minimize it.
- Click a minimized task to restore it. It keeps its tiled or floating mode.
- Right-click a task for window actions. Right-click a pin to launch or reorder it.
- Tasks follow window opening order. Focus and minimize/restore do not reorder them.
- Pinned apps stay in place when the task list scrolls. Overflow controls reveal more tasks.
- A pinned app that is running shows an underline on its pin instead of a task
  button. The underline marks the focused window, plain running, and minimized
  states, and the pin counts its windows when it has more than one.
- Clicking a running pin behaves like its task button: restore, minimize, or
  focus. With several windows it steps through them. Ctrl+Click still opens a
  floating window, and the menu opens another instance.
- Right-click a running pin to pick one of its windows, or to minimize, restore,
  or close one of them. Unpin an app to give it task buttons again.
- Hover over the workspace button or tray chevron to reveal its contents.
- Start and taskbar pins are independent. Start applies a changed pin order on its next opening.
- Use search in Start to find and launch apps. Hover hints show how to pin apps
  or open apps and folders in floating windows.
- Taskbar controls accept clicks down to the bottom edge. Start reaches the left edge.
  The final status control reaches the right edge.

The bar appears at the bottom of each screen. Tasks include all workspaces on
that screen. The tray, status controls, and clock appear on every screen.
Panels open beside the control you click; panel shortcuts use the focused screen
unless they are closing a panel that is already open.

## Places in Start

Start includes Home, Recent, Starred, Network, and Trash. Below those, it shows
your bookmarks from Files, with the same names and order. Click a place to
open it in Files.

Manage these bookmarks in Files. Add, rename, reorder, or remove one, and Start
updates automatically. Places are separate from your pinned apps.

## Keyboard shortcuts

Window context menus show Omarchy's shortcuts beside the actions they perform.
Tilelane also keeps Omarchy's panel shortcuts working. It does not install or
rewrite Omarchy's bindings.

## Configure

Tilelane follows a classic desktop taskbar layout. Start always sits at the
far left, with the workspace switcher beside it. Pinned apps and open windows
come next. The clock stays at the far right. Tray icons and status widgets
sit together to the left of the clock, with small gaps between groups.

You can rearrange those status widgets through Omarchy. Start, the workspace
switcher, and the task area stay in place.

Omarchy's section names describe its own bar. Tilelane fits those sections
into this taskbar layout:

- The `right` section holds the tray and controls such as Bluetooth, Network,
  and Volume. They stay together on the right side of Tilelane.
- The `center` section holds items such as Language, Weather, and Updates.
  They sit between those controls and the clock. The clock goes at the far
  right, even though Omarchy puts it in `center`.
- The `left` section normally holds Omarchy's menu and workspaces. Tilelane
  provides Start and its own workspace switcher instead. If you add other
  widgets to `left`, they join the status area, before the `right` widgets.

Within each group, your chosen order still applies. For example, to put
Volume before Bluetooth:

```sh
omarchy bar move omarchy.audio --section right --before omarchy.bluetooth
```

Volume moves within the status area. Start, the workspace switcher, and the
clock stay where they are. Omarchy's indicators appear inside Start.

Use `omarchy plugin enable` and `omarchy plugin disable` for optional widgets.
Dropbox, for example, belongs to Omarchy's `right` section by default and
appears alongside the other controls. Application tray icons appear in the
tray drawer. Some widgets only appear when needed, such as Power on a laptop
with a battery or Updates when updates are available.

Change a widget's settings with Omarchy too:

```sh
omarchy bar set omarchy.clock format 'h:mm AP'
```

Changes apply without restarting the shell.

Existing status controls share Tilelane's hover, keyboard-focus, and panel
underline styling. Other plugins keep their own visual content and mouse
actions inside the shared host, so their internal styling may differ.
The bar stays at the bottom of the screen.

Tilelane saves taskbar pins, Start pins, identity overrides, and reduced motion
in Omarchy's `~/.config/omarchy/shell.json`. Changes apply without a restart.
See [settings and recovery](docs/recovery.md#recover-pins-or-settings) for the fields.

Set reduced motion with:

```sh
omarchy-shell tilelane reducedMotionSet true
omarchy-shell tilelane reducedMotionState
omarchy-shell tilelane reducedMotionSet false
```

Only `true` and `false` are accepted. This changes `bar.reducedMotion` in
Omarchy's settings.

## Update or remove

For a Git-managed installation with an upstream remote:

```sh
omarchy plugin update io.github.lexeko.tilelane
omarchy restart shell
```

A manually copied installation needs a new complete copy instead.
Do not overwrite its user data when updating plugin code.

To remove the installed plugin:

```sh
omarchy bar reset
omarchy plugin remove io.github.lexeko.tilelane
```

Tilelane's settings remain in `shell.json` after removal. See
[recovery](docs/recovery.md) for cleanup and minimized-window recovery.

## Documentation

- [Recovery and diagnostics](docs/recovery.md)
- [Changelog](CHANGELOG.md)
- [Architecture](docs/architecture.md)
- [Contributing](CONTRIBUTING.md)

## License

[MIT](LICENSE). Copyright (c) 2026 Alexey Konoplev.

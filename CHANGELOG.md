# Changelog

## 0.2.0 (Spine)

Spine is a fork of [lexeko/tilelane](https://github.com/lexeko/tilelane) by
Alexey Konoplev. Releases `0.1.0` and `0.1.1` below are upstream's.

It installs as `io.github.thenobody0817.spine`, so it sits alongside upstream
Tilelane instead of replacing it. Its settings keys, IPC target, and minimize
journal keep their upstream `tilelane` spelling so existing pins and minimized
windows carry over.

### Added

- A pinned app that is running now shows its state on the pin instead of a
  separate task button, so it appears once rather than twice.
- Pinned taskbar apps match their windows ignoring case and an optional
  `.desktop` suffix, so a stored pin finds the windows it should collapse.
  Stored pins keep whatever you wrote; Tilelane does not rewrite them.
- A pin's underline marks a focused window, plain running, and minimized states,
  and urgent windows take priority over focus. A pin with several windows shows
  a count.
- Clicking a running pin restores, minimizes, or focuses like its task button,
  and steps through the app's windows when it has more than one.
- A running pin's right-click menu lists the app's windows. Selecting one
  focuses it, and each row offers minimize or restore and close.
- New read-only `pinState` and `pinCollapses` diagnostics report which windows
  each pin has collapsed.
- Collapsing is always on for pins and adds no stored setting. Unpin an app to
  give it its own task buttons again.
- The plugin id, install path, and product name changed to `Spine`, so this fork
  can be installed alongside upstream Tilelane.

### Known gaps

- The second monitor, urgent-state rendering, and the picker's per-window
  minimize, restore, and close buttons have not been checked live. See
  [behavior and test coverage](docs/behavior-matrix.md#checks-that-remain-open).

## 0.1.1

- Display bookmark names and other Tilelane labels as plain text, preventing
  embedded markup from changing their appearance or loading inline images.

## 0.1.0

First release.

- A bottom taskbar on each monitor, inside Omarchy's existing shell process.
- One task per window, kept in opening order across focus and minimize changes.
- Minimize and restore that preserve tiled or floating mode and pointer position.
- Separate taskbar and Start pins, app search, and Files bookmarks in Places.
- Desktop-entry icons, with terminal-app and web-app matching.
- Normal and floating launches for apps and folders.
- Window context menus with Omarchy's shortcut hints.
- Per-monitor workspace switching, tray icons, and configured Omarchy widgets.
- Native panel shortcuts, with panels opening on the relevant monitor.
- Dynamic widget loading, stable panel state during reordering, and cleanup on reload.
- Start dismissal on outside clicks, including clicks on another monitor.
- Omarchy themes, menu rounding, and shared hover and open-panel styling.
- Screen-edge click areas, delayed hover drawers, and fading task overflow.
- Keyboard navigation, accessible names, and reduced motion.
- Pins and preferences stored in Omarchy's shell settings.

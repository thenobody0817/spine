# Contributing to Spine

Read the [architecture](docs/architecture.md) before changing window actions,
settings, or native widget integration. Keep documentation in simple language
and update it when behavior changes.

## Development setup

Follow the [installation instructions](README.md#install) to load a complete
copy of the plugin. Keep changes in this repository and copy the affected
runtime files into the installed plugin directory.

Omarchy watches installed plugin files. If a changed component stays cached,
run `omarchy restart shell`. The plugin runs inside Omarchy's existing shell.
Do not start another Quickshell process to run the bar.

## Checks

Run these commands from the repository root:

```sh
omarchy plugin validate .
./scripts/check
```

The checks use Qt's QML tools and Python 3. Node and Lua run the pointer regression tests.
Install ShellCheck for shell linting. The check script reports tools it skips.

After installing and selecting Spine, run `./scripts/smoke`.
For input or window behavior, also test the affected action in the live bar.
Tray rendering changes need the [shader rendering tests](qml/shaders/README.md).

For widget integration, `tests/fixtures/dynamic-widget` provides a plugin with
a custom entry point, configurable label, and native panel. Install a copy in
the user plugin directory and enable `local.tilelane-dynamic-test` to check
discovery, settings updates, ordering, and removal in the live bar. Remove the
fixture with `omarchy plugin remove local.tilelane-dynamic-test --yes` afterward.
The automated checks also exercise manifest loading in an isolated, headless
Quickshell process without changing the desktop configuration.
Window-model checks load the production model without a compositor connection.
They cover opening order, state updates, stale close events, and source cleanup.
A separate test sends Hyprland events through local test sockets. It checks
floating-state refreshes, rapid toggles, and windows closed before a refresh.

Documentation-only changes need a link and factual review, not UI tests.

## Reference

- [Behavior and test coverage](docs/behavior-matrix.md)
- [Performance records](docs/performance.md)
- [Appearance and reference images](docs/visual-parity.md)

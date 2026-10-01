#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
shell_pid=""
stop_shell() {
  if [[ -n "$shell_pid" ]]; then
    kill "$shell_pid" 2>/dev/null || true
    wait "$shell_pid" 2>/dev/null || true
    shell_pid=""
  fi
}
cleanup() {
  stop_shell
  rm -rf -- "$test_dir"
}
trap cleanup EXIT
mkdir -p "$test_dir/qml/models"
cp "$repo_dir/tests/quickshell/settings.qml" "$test_dir/shell.qml"
cp "$repo_dir/qml/models/TilelaneSettings.qml" "$repo_dir/qml/models/PinnedApplications.qml" "$test_dir/qml/models/"
cp "$repo_dir/qml/SettingsLogic.js" "$repo_dir/qml/AppIdentity.js" "$test_dir/qml/"

start_shell() {
  rm -f "$test_dir/state.json"
  printf '{"id":0}\n' >"$test_dir/action.json"
  QT_QPA_PLATFORM=offscreen TILELANE_SETTINGS_TEST_DIR="$test_dir" \
    quickshell --path "$test_dir" --no-color >"$test_dir/result.log" 2>&1 &
  shell_pid=$!
}
await_state() {
  local query="$1" label="$2"
  for ((attempt = 0; attempt < 100; attempt++)); do
    if jq -e "$query" "$test_dir/state.json" >/dev/null 2>&1; then return; fi
    sleep 0.05
  done
  printf 'Settings failed: %s\n' "$label" >&2
  cat "$test_dir/result.log" >&2
  cat "$test_dir/state.json" >&2 || true
  return 1
}
edit_config() {
  jq "$1" "$test_dir/shell.json" >"$test_dir/replacement"
  mv "$test_dir/replacement" "$test_dir/shell.json"
}

printf '%s\n' '{"version":1,"bar":{"id":"io.github.thenobody0817.spine","layout":{"right":[{"id":"omarchy.clock","format":"HH:mm"}]}},"idle":{"lock":600},"plugins":[{"id":"example.service","value":42}]}' >"$test_dir/shell.json"
printf '%s\n' '{"version":1,"pins":["old-pin"],"overrides":{"terminal":"editor"},"reducedMotion":true}' >"$test_dir/legacy.json"
cp "$test_dir/legacy.json" "$test_dir/legacy-original.json"
start_shell
await_state '.loaded and .values.reducedMotion and .values.tilelaneIdentityOverrides.terminal == "editor" and .pins == [] and .startPins == []' 'import preferences, reset pins'
printf '%s\n' '{"id":1,"kind":"pin","value":"browser"}' >"$test_dir/action.json"
await_state '.actionId == 1 and .actionResult and .pins == ["browser"] and .startPins == []' 'taskbar pin'
printf '%s\n' '{"id":2,"kind":"startPin","value":"files"}' >"$test_dir/action.json"
await_state '.actionId == 2 and .actionResult and .pins == ["browser"] and .startPins == ["files"]' 'independent Start pin'
printf '%s\n' '{"id":3,"key":"reducedMotion","value":false}' >"$test_dir/action.json"
await_state '.actionId == 3 and .actionResult and (.values.reducedMotion | not)' 'disable motion preference'
printf '%s\n' '{"id":4,"key":"id","value":"other.bar"}' >"$test_dir/action.json"
await_state '.actionId == 4 and (.actionResult | not) and .writes == 4' 'reject unrelated setting'
cmp "$test_dir/legacy.json" "$test_dir/legacy-original.json"
jq -e '.bar.layout.right[0].format == "HH:mm" and .idle.lock == 600 and .plugins[0].value == 42 and .bar.tilelaneIdentityOverrides.terminal == "editor"' "$test_dir/shell.json" >/dev/null
stop_shell

# A restart must not read the old file or import its true value again.
printf 'invalid old settings\n' >"$test_dir/legacy.json"
start_shell
await_state '.loaded and .writes == 0 and .error == "" and (.values.reducedMotion | not) and .pins == ["browser"] and .startPins == ["files"]' 'restart ignores legacy file'
edit_config '.bar.tilelanePins = ["external"] | .bar.reducedMotion = true'
await_state '.pins == ["external"] and .values.reducedMotion and .writes == 0' 'external settings reload'
edit_config '.bar.tilelanePins = "invalid"'
await_state '.pins == [] and .startPins == ["files"] and .values.reducedMotion and (.error | contains("tilelanePins")) and .writes == 0' 'invalid field preserves other settings and disk data'
edit_config '.bar.tilelanePins = ["restored"]'
await_state '.pins == ["restored"] and .error == ""' 'corrected settings recover'
edit_config '.bar.id = "omarchy.bar"'
await_state '(.loaded | not)' 'bar reset'
printf '%s\n' '{"id":1,"kind":"pin","value":"blocked"}' >"$test_dir/action.json"
await_state '.actionId == 1 and (.actionResult | not) and .writes == 0' 'inactive bar cannot write'
edit_config '.bar.id = "io.github.thenobody0817.spine"'
await_state '.loaded and .pins == ["restored"] and .writes == 0' 're-enable retains settings'
stop_shell

# Fresh installation has no dependency on either old pin file.
rm "$test_dir/legacy.json"
printf '%s\n' '{"bar":{"id":"io.github.thenobody0817.spine"}}' >"$test_dir/shell.json"
start_shell
await_state '.loaded and .error == "" and .pins == [] and .startPins == [] and (.values.reducedMotion | not) and .writes == 1' 'fresh installation'
stop_shell

# Do not silently drop preferences when legacy input is damaged.
printf '%s\n' '{"bar":{"id":"io.github.thenobody0817.spine"}}' >"$test_dir/shell.json"
printf 'invalid legacy settings\n' >"$test_dir/legacy.json"
start_shell
await_state '(.loaded | not) and .writes == 0 and (.error | contains("Cannot import"))' 'invalid legacy settings are preserved'
printf 'Settings persistence: pass\n'

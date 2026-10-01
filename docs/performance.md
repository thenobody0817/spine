# Performance

Measured on 2026-09-27 against upstream Tilelane runtime code from `f284b70`,
before this fork existed. The `0.1.0` release draft has the same runtime files.
Spine changed the task list and pin rendering since then, so these figures
describe the base the fork started from, not current Spine.
These figures describe one session, not a comparison with the stock bar.

## Environment

Omarchy 4.0.4-1, Hyprland 0.56.2, Quickshell 0.3.1, and Qt 6.11.2.
Hyprland used its FALLBACK display at 1920 by 1080 and scale 1.
This does not measure rendering on a physical display.
Spine shared the normal Omarchy shell process and its configured widgets.

No battery was present. The package energy counter required root access and
was not read. These results establish no power or battery benefit.

## Ten-minute idle sample

After a 30-second settling period, the test read CPU ticks and resident memory
from `/proc` every five seconds for 600 seconds. No compositor events occurred
during the sample. A few read-only diagnostic calls ran near the start.
CPU usage below measures the whole shell as a percentage of one CPU core.

| Measurement                    | Result                                        |
| ------------------------------ | --------------------------------------------- |
| Mean shared-shell CPU          | 0.038% of one core                            |
| Resident memory at start       | 456656 KiB                                    |
| Resident memory at end         | 454912 KiB                                    |
| Resident memory range          | 454784 to 456912 KiB                          |
| Direct children at each sample | One plugin watcher and two clipboard watchers |

The snapshots did not show new child processes. Five-second sampling cannot
rule out short-lived processes between samples. Source review found no
recurring Spine-owned subprocess polling. Hosted widgets keep their own
refresh schedules.

## Window lifecycle and latency

All 60 test windows opened, appeared in Spine's model, closed, and left the
model. Each cycle returned to the original window count. Shared-shell memory
changed from 455932 KiB to 454912 KiB.

The latency figures exclude ten warmup cycles and use the remaining 50.
The event measurements start when the test receives Hyprland's socket event.
They include polling and an IPC round trip to observe Spine's model.
They do not measure when a frame reaches the display.

| Measurement                   | 95th percentile |
| ----------------------------- | --------------- |
| Process launch to model entry | 73.0 ms         |
| Open event to model entry     | 36.7 ms         |
| Close event to model removal  | 34.5 ms         |

## Panel lifecycle

Audio, network, Bluetooth, display, clock, weather, and Dropbox each completed
one warmup cycle and ten measured open/close cycles. All 77 cycles passed.
No new shell diagnostics appeared during the window or panel tests.

Resident memory rose when panels first loaded. After warmup, the end-of-round
samples ranged from 463628 to 467964 KiB and finished at 466932 KiB.
The samples did not show steady growth. This short run does not rule out a
slow leak. Native widgets may keep components or caches loaded after closing.

## Work that can start a process

The [architecture inventory](architecture.md#processes-and-commands) lists
process triggers. These include app launch, hidden-entry scans, terminal
identity probes, shortcut lookup, and window actions.

Floating launch can poll new clients up to 40 times after a user request.
Terminal identification allows bounded startup retries. A window without a
PID can request a batched detail refresh. Hover, collapse, unload, and hint
timers manage UI state without recurring idle subprocess queries.

## Repeat the measurements

Record versions, active widgets, output scale, shell PID, and background activity.
Useful read-only commands include:

```sh
omarchy version
omarchy-shell shell ping
hyprctl monitors -j
pgrep -a -x quickshell
ps -eo pid,ppid,etimes,%cpu,rss,comm,args
```

Process output can contain private application arguments. Review it before sharing.

For a stock-bar comparison, alternate stock and Spine runs under the same
conditions. Measure each for ten minutes and report the median across runs.
Keep raw CPU ticks, memory samples, child processes, and compositor event counts.
Separate process launch time from compositor-event latency.

Use controlled test windows. Restore the prior bar, focus, and pointer after
testing. Physical display scaling, cable events, and suspend/resume need their
own checks. The fallback-display measurements above do not cover them.

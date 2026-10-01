# Appearance and visual references

The current source and accepted design changes define Spine's appearance.
Historical screenshots do not replace a current visual baseline.

## Current layout

Dimensions below are base logical pixels unless noted. Spine applies
Omarchy's spacing and font scale. Output scale changes physical rendering.

| Part             | Current design                                                                           |
| ---------------- | ---------------------------------------------------------------------------------------- |
| Bar              | Bottom edge, base height 44                                                              |
| Start            | Visible height 36, minimum visible width 90, click area reaches left and bottom edges    |
| Workspace button | 32 by 32 control, 18 by 18 numbered icon, taskbar body font for the number               |
| Pinned apps      | Fixed row outside the task viewport                                                      |
| Running tasks    | Visible height 36, 4-pixel gaps, one button per window                                   |
| Section gaps     | 12 pixels between Start, workspace, task lane, and right group                           |
| Task overflow    | Control height matches the task button, glyph width plus 16 pixels of horizontal padding |
| Overflow glyphs  | Shared Omarchy chevrons; bar glyphs are larger than the compact Start-menu version       |
| Task fade        | Up to 24 pixels at each overflowing viewport edge                                        |
| Tray slots       | 30 by 32, with a bottom-edge click extension                                             |
| Clock            | Visible height 36, minimum width 76, underline matches the text width                    |
| Start card       | At most 736 by 648, constrained to the screen                                            |
| Start rows       | App rows 42, place rows 38, app icons 28                                                 |

The tray and workspace fan wait 200 ms before opening on hover.
Workspace blades use opaque fills. The shared body font sizes task labels,
the workspace number, and clock text.

## Omarchy styling

Colors and fonts come from `qs.Commons` roles. Start uses
`Commons.Style.cornerRadius` for its outer card. Native menu containers follow
Omarchy's panel styling. Small controls and menu rows keep their local radii.
It would be inaccurate to say that every rectangle inherits window rounding.

Dividers use Omarchy's hairline size and a faint menu-text color.
Open tray controls and the clock use an underline. Task buttons also use an
underline for active or open-menu state. Keyboard focus remains visible.

The clickable area can be larger than the visible frame. Extending clicks to
the screen edge does not stretch the icon, text, or underline.

## Project preview

[The project preview](../preview.png) shows the full desktop with Spine's
taskbar and Start menu open.

## Earlier visual checks

The earlier scale review used a temporary output at scale 1, 1.25, 1.5, and 2.
With default UI sizing, crops measured 44, 55, 66, and 88 physical rows.
The bar remained 44 logical pixels high.

For the Tokyo Night colors used in that review, the recorded contrast ratios
were 8.10:1 for bar text, 6.79:1 for the accent, and 6.46:1 for urgent color.
These values describe those colors only. They do not certify other themes
or the entire interface's accessibility.

No complete pixel-difference or SSIM result is available for Start and tray
scenes in light and dark themes. Later manual checks covered the changed
controls, but do not establish a whole-interface visual baseline.

## Check a visual change

Capture the changed control in normal, hover, pressed, open, and keyboard-focus
states when those states apply. Check a long task title, overflow, and a narrow
screen if the change affects layout. Check the bottom-edge hit area separately
from the visible frame.

Use the same theme, font, screen scale, and scene when comparing images.
Record the source revision and capture conditions. Use `tests/output/` for
local captures.

New window title bars are outside the current implementation.

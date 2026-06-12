# Custom Fonts (Input Fields & Tab Titles) — Spec

Status: approved
Last updated: 2026-06-12

## Goal
Add two new configurable fonts — "Input Field Font" and "Tab Font" — so a user can set a monospaced font (e.g. JetBrains Mono) on typable fields and folder-tab titles that currently inherit the system/control font.

## Background
Double Commander already has a font-configuration system: enum `TDCFont`, record `TDCFontOptions`, global `gFonts: TDCFontsOptions`, an Options → Fonts page (`TfrmOptionsFonts`), XML load/save in `uglobs.pas`, and the `FontOptionsToFont` / `FontToFontOptions` converters. Paths and filenames shown in the file panel use `dcfMain`; the address bar uses `dcfPathEdit`; inline rename follows `dcfMain`. Those stay as they are.

Two display/input surfaces have no configurable font today, and this feature fills both:
1. Typable input fields (mkdir, multi-rename, command line, quick search) — inherit the system font.
2. Folder-tab titles — the tab strip is a native `TPageControl` (`TFileViewNotebook` in `ufileviewnotebook.pas`, pages are `TTabSheet`) with no font wiring; captions use the control default.

## Non-goals
- No new font for the file panel, address bar, or inline rename — already covered by `dcfMain` / `dcfPathEdit`.
- No unified "path/filename" font overriding existing categories.
- No per-field input fonts and no grouping of inputs by kind — one shared input font for all four fields.
- No change to existing font picker mechanics, zoom behaviour, or font-quality handling.

## Font categories added

### `dcfInput` — "Input Field Font"
Monospace-oriented. Picker uses `fdFixedPitchOnly` (same as Editor/Viewer/Log/Console rows). Default: name = MonoSpaceFont, size = 12, style = none, MinValue 6, MaxValue 200.

Applied to:
- MkDir dialog — `cbMkDir` combo (`fmkdir.pas`).
- Multi-rename tool — `edFind`, `edReplace`, `edPoc`, `edInterval`, and the preview `StringGrid` (`fmultirename.pas`).
- Command line — `edtCommand` bar at bottom of main window (`fmain.pas`).
- Quick search / filter — `edtSearch` (`frames/fquicksearch.pas`).

### `dcfTabs` — "Tab Font"
Display category (not constrained to monospace in the picker, consistent with `dcfMain` / `dcfPathEdit`); the user picks a monospaced font if desired. Default: name = 'default', size = 10, style = none, MinValue 6, MaxValue 200.

Applied to:
- Folder-tab titles — set `Font` on the `TFileViewNotebook` (`TPageControl`) for both panels, where other main-window fonts are applied in `fmain.pas`. One control-level font covers all tab captions.

## User-facing behaviour
Two new rows on Options → Fonts page, labelled "Input Field Font" (`rsFontUsageInput`) and "Tab Font" (`rsFontUsageTabs`). Each behaves like the existing font rows: read-only name preview (`TEdit`), size `TSpinEdit` (min/max above), and a "..." button opening `TFontDialog`. Settings persist to XML under `Fonts/Input` and `Fonts/Tabs` and restore on next launch.

## Implementation outline
Mirror the existing `dcfSearchResults` / `dcfPathEdit` plumbing end to end for both new values:

- `uglobs.pas` — add `dcfInput` and `dcfTabs` to the `TDCFont` enum; add their defaults in the init block (per the categories above); add `GetDCFont(... 'Fonts/Input' ...)` and `GetDCFont(... 'Fonts/Tabs' ...)` in `LoadXmlConfig`, and matching `SetDCFont` calls in `SaveXmlConfig`. No config-version gate needed — when a node is absent, `GetDCFont` falls back to the default (the `>= 11` gate on SearchResults existed only to discard a stale prior setting). Bump `ConfigVersion` 16 → 17 for traceability (per team convention; no load branches on it).
- `ulng.pas` + language files — add `rsFontUsageInput` and `rsFontUsageTabs`; load them into `gFonts[].Usage` alongside the other usage labels.
- `foptionsfonts.pas` — the Fonts page builds rows by iterating font types, so both new values surface automatically; confirm they appear and that `dcfInput` (not `dcfTabs`) is added to the monospace set that passes `fdFixedPitchOnly`.
- Apply via `FontOptionsToFont(gFonts[dcfInput], <control>.Font)` at the four input sites listed under `dcfInput`, and `FontOptionsToFont(gFonts[dcfTabs], <notebook>.Font)` at the tab site — placed near where `dcfFunctionButtons` / `dcfTreeViewMenu` are currently applied in `fmain.pas`.

## Edge cases
- Config from an older version lacking the new nodes → defaults applied (no error).
- Font set to a non-monospaced name via edited config XML → honoured as-is; the picker only constrains interactive selection, not stored values.
- Size 0 → follow existing convention (system default size); not the chosen default for either category.
- Multi-rename `StringGrid` row height → a larger font may need row auto-sizing so rows aren't clipped; verify after the font change.
- Tab font on native Windows tab control → setting `TPageControl.Font` should re-layout tab height; verify captions aren't clipped and tab height adjusts. Repaint if needed after applying.

## Verification / screenshots
Once implemented, the user wants to capture screenshots in dark mode with a monospaced font (JetBrains Mono) set across the elements specified here — to review how the typable fields and tabs look. Defer screenshotting to a verification pass after implementation.

## Follow-ups
- Possible later: distinguish input fields by kind (path-entry vs tool) if one shared input font proves too coarse. Deferred (single input font).
- Possible later: zoom support (Ctrl+Wheel) for input fields, mirroring address-bar zoom. Not in this feature.

## Out of scope
- A unified path/filename font overriding `dcfMain` / `dcfPathEdit`.
- Per-control font customization beyond the listed fields and the tab strip.

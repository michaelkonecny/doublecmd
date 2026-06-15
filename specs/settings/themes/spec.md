# Theme — Spec

Status: draft
Last updated: 2026-06-15

## Goal
Decoupled, shareable appearance. Colors and fonts are separate theme libraries: the user picks a color theme for light mode, a color theme for dark mode, and a font theme — and can optionally bundle the three under one named Theme set selected in a single click. Themes import/export as versioned JSON files, replacing today's two hardwired OS-dark-mode color sets.

## Background
DC already has most of the pieces, disconnected:

- Colors — `TColorThemes` (`src/ucolors.pas`) holds two hardwired `TColorTheme` instances (Light/Dark) covering FilePanel, Path, FreeSpaceInd, Log, SyncDirs, Viewer, Differ, ProgressBar, TreeViewMenu. The active one is chosen by `DarkStyle` (`Current`/`StyleIndex`), not by the user. Persisted via `gStyles` (`TJsonConfig`) as a named `Styles` array; `Save`/`Load` already serialise both. `LoadFromXml` is a legacy one-way reader for pre-v14 XML configs.
- Fonts — `gFonts: TDCFontsOptions` (`src/uglobs.pas`), one set indexed by the `TDCFont` enum, reorganised by the font-settings hierarchy (categories → subcategories with whole-font inherit). Each role: Name/Size/Style/Quality/Min/Max. No named font themes exist today.
- `MonoSpaceFont` (`src/platform/uOSUtils.pas`) is a per-OS guaranteed monospace family; `'default'` is the LCL system-UI-font sentinel.

This feature turns colors and fonts into independent, user-selectable, importable theme libraries and adds an overarching Theme set.

## Building blocks

Color theme
- Role: a single-variant named color set — the full `TColorTheme` group set.
- Notes: not intrinsically light or dark; light/dark is decided by which slot it's assigned to. Library of N.
- Built-ins: `Light Default`, `Dark Default` (from today's two `TColorTheme` instances). Immutable.

Font theme
- Role: a named snapshot of every font-role value (font-settings hierarchy nodes, with inherit).
- Notes: mode-independent — one font theme applies in both light and dark. Library of N.
- Built-in: `Default Fonts` (from current `gFonts` defaults). Immutable.

Theme set
- Role: a named bundle referencing three themes — `{ lightColor, darkColor, font }`.
- Notes: the one-click overarching selector. Library of N.
- Built-in: `Default` → `{ Light Default, Dark Default, Default Fonts }`. Immutable.

## Active selection
Three independent picks form the live appearance:

- Light color theme — from the color library.
- Dark color theme — from the color library.
- Font theme — from the font library.

Color mode:
- Auto — DC swaps the active color theme between the light and dark picks by `DarkStyle` (replaces today's hardwired index).
- Fixed — one chosen color theme regardless of OS dark mode.

The font theme is constant across modes (fonts don't vary by light/dark).

## Theme set selection and "Custom"
A Theme set selector sits above the three individual pickers.

- Selecting a set applies all three picks at once (lightColor, darkColor, font).
- Changing any individual pick afterwards detaches from the named set: the set selector shows Custom — a transient, unnamed selection of the three current picks.
- Custom is not stored as a named set until the user exports/saves it (Export from current settings). It simply means "these three picks no longer match any named set."
- Re-selecting a named set discards Custom and reapplies that set's three.

## Editing themes (the create-a-theme flow)
Editing is direct on the selected theme — there is no separate per-setting override layer.

- Color option pages edit a color theme. Because two color themes are active (light slot, dark slot), the Colors area carries a "which slot to edit" choice (Light / Dark); each color theme is single-variant, so no side-by-side columns.
- Font option pages edit the selected font theme (over the font-settings hierarchy).
- Built-ins are immutable: the first edit auto-forks the built-in to a user theme (a copy under a new name) and switches the relevant pick to the fork. The user never edits a built-in in place.

No user-override layer (decided): editing is direct, built-ins auto-fork. Rationale: matches "configure colours/fonts, then export to share"; one fewer concept; export = snapshot of the selected themes.

## Cross-platform font model
A theme cannot promise an identical face on every OS the way it can promise colours. In-memory a font theme stores one concrete family per role (plus Size/Style/Quality/Min/Max) with hierarchy inherit — no family chains in live settings. Portability is added only at export.

- Portable, always applied — Size, Style, Quality. Imposed verbatim everywhere, even when the face falls back. Keeps the typographic rhythm consistent. Size `0` means "use the OS default font size" (LCL size-0 sentinel).
- Best-effort — the chosen family. First choice on import; resolved face may differ across platforms.
- Guaranteed — a same-pitch fallback recorded at export, so a role always resolves.

## Font fallback (derived at export)
When a font theme (or a set's font part) is written, for each role's chosen font, export detects its pitch and records `[chosen family, same-pitch sentinel]`:

- detected fixed-width → `MonoSpaceFont`
- detected proportional → `'default'`

On import/apply: chosen family if installed, else the recorded sentinel (OS default of the same pitch), at the saved size/style. The fallback pitch follows the picked font, not the role.

Pitch detection: portable LCL glyph-advance heuristic (narrow vs wide glyph widths in the chosen family/size); native APIs optional. Used only at export — no in-app pitch validation or warning. A misdetected oddball degrades gracefully (chosen family still applies where installed; only the fallback pitch is best-effort).

Totality (every role always resolves):
- Export always appends the detected-pitch sentinel — written font themes are complete by construction. Export is never blocked on fonts.
- Load/apply backstop — on a foreign or hand-edited file, DC appends a sentinel to any role lacking one (pitch re-detected from the listed family, else `'default'`).

## File format
Versioned JSON. Three exportable kinds, each one file:

- Color theme — Name + the `TColorTheme` group set + schema version. Reuses the existing `Styles` color shape per theme.
- Font theme — Name + per-role entry (family + size/style/quality + recorded same-pitch fallback, or `inherit`) + schema version.
- Theme set — Name + embedded copies of its three themes (lightColor, darkColor, font) + schema version. Self-contained: sharing a set hands over light colours, dark colours, and fonts in one file. Does not carry color mode (Auto/Fixed) — mode is local app state, so a shared set never forces the recipient's switching behaviour.

Schema version is an integer per file: reject newer-than-supported (clear message); migrate older forward in memory.

## Export / import
- Export from current settings — builds a Theme set from the three active picks, embeds them, prompts for a name, writes `.json`. Optional "add to my libraries" registers the set (and its embedded color/font themes) for reuse (default on). This is also how a Custom selection is saved.
- Export a single theme — write the selected color theme or font theme alone.
- Import — a color/font file adds to its library; a set file adds the set plus its three embedded themes (name-collision handling under Edge cases).

## Resolution order
- Colour value = active colour theme's value (light or dark pick, per mode).
- Font value = active font theme's role value (honouring hierarchy inherit) → chosen family if installed, else the recorded same-pitch fallback.

## User-facing behaviour
Options area (extends Colours and Fonts):

- Theme set dropdown — built-in + user sets, plus Custom when picks deviate.
- Three pickers — light colour theme, dark colour theme, font theme. Mode toggle (Auto / Fixed); Fixed shows a single colour picker.
- Load button — import a `.json` (colour, font, or set) into the right library.
- Export current settings button — see Export / import; name prompt + "add to my libraries".
- Colour pages edit the chosen colour theme (with the Light/Dark slot choice); font pages edit the chosen font theme. Editing a built-in auto-forks.

Selecting themes/sets or editing values reflects live in panels/UI (same refresh path as today's colour/font apply).

## Edge cases
- Import schema newer than supported → reject with a message naming the version; nothing added.
- Import schema older → migrated forward in memory, then added.
- Imported name collides with an existing theme/set → import under a de-duplicated name; never overwrite a built-in.
- Set import where an embedded theme's name collides → embedded themes de-duplicated independently; the set references the de-duplicated copies.
- Imported font entry missing a fallback → load/apply backstop appends a same-pitch sentinel; import always succeeds.
- Imported font family not installed → recorded sentinel used; resolves silently.
- Attempt to overwrite/delete a built-in → blocked; editing a built-in produces a user fork instead.
- A set's referenced theme is missing (e.g. deleted) → that slot falls back to the corresponding built-in (`Light Default` / `Dark Default` / `Default Fonts`).
- Auto-switch slot left unset → corresponding built-in used.
- Old config (pre-feature) → today's Light/Dark colour sets become `Light Default`/`Dark Default`, assigned to the two slots; current fonts become `Default Fonts`; mode Auto. Preserves existing behaviour.
- A font role absent from an imported font theme (older export) → that role uses the built-in default.

## Verification
- Built-ins resolve: `Light Default`/`Dark Default` give a concrete colour for every group; `Default Fonts` resolves every role to a concrete installed font.
- Set selection applies all three picks; changing one pick flips the set selector to Custom; re-selecting a set restores its three.
- Auto mode switches the active colour theme by `DarkStyle`; Fixed mode ignores it; font theme unchanged across modes.
- Pitch detection: a known fixed-width family detects fixed; a known proportional family detects proportional.
- Export never blocked on fonts; each role written with a same-pitch sentinel (fixed→`MonoSpaceFont`, proportional→`'default'`).
- Load/apply backstop: a font entry lacking a fallback resolves after load.
- Export-from-current round-trip: configure picks + edits, export the set, re-import → the three themes and effective colours/fonts match; an inheriting font subcategory stays `inherit`; chosen family exports as `[family, same-pitch sentinel]`.
- Built-in immutability: editing a built-in forks to a user theme and switches the pick; the built-in is unchanged.

## Implementation notes
- `TColorTheme.Assign` (`ucolors.pas`) currently omits `ProgressColors` — fix when themes start being copied/forked, or fork logic will drop progress-bar colours.
- Storage unifies in the JSON config (`gStyles`): colour library, font library, theme-set list, and the selection/mode block all live there. The colour `Styles` array grows beyond today's fixed two entries to N named themes + a `{lightName, darkName}` selection. Font themes migrate out of `doublecmd.xml` into a parallel font library in `gStyles`; the live applied `gFonts` is derived from the selected font theme. Plan a one-time migration of existing `doublecmd.xml` font values into a user font theme.

## Follow-ups
- Optional per-OS family overrides per role for authors wanting tuned faces per platform (shared value used when an OS-specific one is absent). Deferred.
- Light/dark tagging of colour themes to filter the slot dropdowns, if untagged lists get unwieldy.
- Theme package (zip) bundling font files with runtime font-registration (Win `AddFontResourceEx`, macOS `CTFontManagerRegisterFontsForURL`, Linux `FcConfigAppFontAddFile`) + licensing acknowledgement. Out of scope here.

## Out of scope
- Bundling/distributing font files inside a theme (v1) — font licensing + no runtime font-registration code yet. See Follow-ups.
- In-app pitch validation or warnings — detection runs only at export.
- Per-control theming beyond the existing colour groups and font roles.
- File-types colours (`gColorExt`) — a separate, single-variant store outside `TColorTheme`; not part of colour themes.

## Open questions
- Exact JSON schema for each file kind (colour theme, font theme, theme set) and the in-config layout of the libraries + selection/mode block + version attribute name — pin during `/implementation-plan`.
- Migration details for moving `doublecmd.xml` font values into a `gStyles` font theme (naming of the migrated theme, rollback if config downgraded).

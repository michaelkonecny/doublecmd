# Font Settings — Tests

Status: agreed
Last updated: 2026-06-15

Harness: `src/dcfonttests.lpr` (fpcunit console runner), units under `src/test/`.
Tiers — Tier-2: logic/constants, no GUI; Tier-3: isolatable forms.

## Tier-2 — resolver & constants

1. Inherit resolves to parent — subcategory with `Inherit=True` yields its category root's font (name, size, style, quality).
2. Override wins — subcategory with `Inherit=False` yields its own values even when they differ from the parent.
3. Parent map correct — every subcategory maps to its intended category root; category roots have no parent.
4. Mono constraint membership — `DCMonoFonts` covers Document (+Editor/Viewer/ViewerBook), Console (+Log), User input; excludes UI and Filesystem (+their subs).
5. ConfigVersion is 18.

## Tier-2 — config migration & round-trip

6. Legacy slots migrate explicit — synthesized v17 XML (`Fonts/Main`, `Fonts/Editor`, …) loads so each mapped slot equals its old values with `Inherit=False`.
7. New-only slots seed correctly — inline rename starts `Inherit=True`; UI root defaults to system font, Document root to mono.
8. Nested round-trip — save then load the new tree (`Fonts/Filesystem/PathEdit`, `Fonts/Document/Editor`, …) preserves fonts and Inherit flags.
9. Missing-node fallback — v17 XML lacking some font nodes loads without error; those slots fall back to default (category) / inherit (subcategory).

## Tier-3 — Options → Fonts page

10. Indented rows — one row per category plus an indented row per subcategory; subcategory rows carry an Inherit checkbox, category rows don't.
11. Inherit disables controls — an inheriting subcategory's size/preview controls are disabled and show resolved parent values; unchecking enables them.
12. User-input widgets unchanged — MkDir/MultiRename/QuickSearch still driven by the User-input slot; numeric counters (`edPoc`, `edInterval`) still default.

## Notes

- Zoom removal has no dedicated test — proven by the build compiling once `gZoomWithCtrlWheel` and the `cm_MainFontZoom*` commands are gone; manual smoke for the wheel itself.
- Existing `TestConfigVersion` (asserts 17) is updated to 18 under test 5.
- Existing form tests fold into test 12.

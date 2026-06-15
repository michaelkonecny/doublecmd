# Font Settings — Implementation Notes

Status: implemented 2026-06-15. All 12 tests green (`src/dcfonttests.lpi`).

## Deviations from the plan

Commits: the `dcfMain`/`dcfConsole` rename forces steps 1–5 to compile as one
unit, and per-hunk staging isn't available in this shell, so the work landed as
one `feat` commit (data model + migration + apply sweep + zoom removal + picker)
plus one `test` commit, rather than six per-step commits.

`ApplyFont` signature is `ApplyFont(AFont: TDCFont; Font: TFont)` (not the
plan's `(Ctrl: TControl; f)`), so it also covers `Canvas.Font` / `SynEdit.Font`
apply sites, not just controls.

Stale flat nodes are dropped by `ClearNode('Fonts')` in `SaveXmlConfig` (then
rewriting the nested tree) rather than `DeleteNode` per old node during load.
Equivalent result; migration stays one-time (gated on `ConfigVersion < 18`) and
idempotent if the app loads a v17 config but exits before saving.

The `Inherit` flag is written on every font node (including category roots) for
uniformity; roots ignore it when resolving. The spec implied only subcategories
store it — the extra attribute is harmless.

Picker preview load uses `FontOptionsToFont(gFonts[AFont], …)` directly — the
one remaining `FontOptionsToFont(gFonts[` outside the `ApplyFont` helper. This
is intentional: the picker edits each slot's own stored values, not the resolved
value.

Viewer book is now monospace-constrained in the picker (spec test 4 lists it
under Document), though its default face stays `default`/16/bold.

## Behaviour change to flag

Inline rename overlay: all three file views (columns, brief, thumbnail) now
drive the rename edit from `dcfInlineRename` (which inherits Filesystem by
default). Brief/thumbnail are unchanged in effect (both already used the panel
font). Columns view previously used the file-name column's own font — so a
custom per-column file-name font no longer styles the inline-rename overlay.

## Test enablement

Exposed `CreateGlobs` and `SetDefaultConfigGlobs` in the `uGlobs` interface so
the headless fpcunit harness can allocate the global lists and seed default
fonts before exercising the real `LoadXmlConfig`/`SaveXmlConfig` — letting the
migration and round-trip tests drive the actual loader rather than a stub.

## Follow-ups

Manual/screenshot pass (spec Verification) not done here — it would migrate the
real `doublecmd.xml` to v18 and needs GUI navigation. Reviewer should, in dark
mode with a monospaced font: confirm picker indentation and the Inherit
checkboxes; change a category font and see inheriting subcategories re-flow
live; check status-bar / search-results row height (no clipping); confirm
Ctrl+Wheel no longer zooms anywhere.

Release notes (project Mantis): record that `cm_MainFontZoomIn` /
`cm_MainFontZoomOut` are removed outright and that custom hotkeys bound to them
are dropped. `doc/changelog.txt` is stale (last entry 2011), so not edited.

Pre-existing, unrelated: the build prints `Error: File "dmhigh.json" not found`
(a resource-packaging step) but continues and links — present before this work.

Toolchain: a stale unit cache triggers an FPC 3.2.2 internal error ("Compilation
raised exception internally"); fix by deleting the unit output dir
(`src/test/lib` for tests, `units/x86_64-win64-win32` for the app) and
rebuilding.

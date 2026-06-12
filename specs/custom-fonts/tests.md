# Custom Fonts — Tests

Goal: everything automated. Three tiers — a lightweight config-primitive suite, an LCL GUI suite for the isolatable forms, and a best-effort in-process `TfrmMain` harness for the surfaces that only exist on the main window. The `TfrmMain` tier is best-effort: if booting the app in-process proves infeasible or flaky, those specific checks revert to manual and the reason is recorded in `plan.md`.

## Tier 1 — config primitive (`dcxmlconfig` component)

Console fpcunit; no LCL.

- Round-trip — `SetFont` then `GetFont` on a node returns identical name/size/style/quality.
- Default fallback — `GetFont` on a missing node returns the supplied defaults unchanged.
- Style bitmask — combined styles (bold+italic) round-trip intact.

## Tier 2 — `uglobs` constants

Requires lifting `cMonoFonts` out of `btnSelFontClick` into a unit-visible const `DCMonoFonts`.

- Picker constraint — `dcfInput in DCMonoFonts` true; `dcfTabs in DCMonoFonts` false.
- Config version — `ConfigVersion = 17`.

## Tier 3 — GUI forms (LCL fpcunit runner)

Initialise the LCL widgetset; set `gFonts[dcfInput]`/`gFonts[dcfTabs]` to a recognisable test font, then instantiate each isolatable form.

- Options frame — `TfrmOptionsFonts` after Init/Load has rows for `dcfInput` and `dcfTabs` (correct `Usage`) and the preview edit shows the configured font name.
- MkDir — `TfrmMkDir.cbMkDir.Font` matches `gFonts[dcfInput]`.
- Multi-rename — `edFind`/`edReplace`/`edPoc`/`edInterval` + `StringGrid.Font` match `gFonts[dcfInput]`.
- Quick search — `edtSearch.Font` matches `gFonts[dcfInput]`.

## Tier 4 — in-process `TfrmMain` harness (best-effort)

Construct `TfrmMain` (or the minimal init path it needs) in the GUI runner with a temp config dir, set the two fonts, and assert:

- Command line — `edtCommand.Font` matches `gFonts[dcfInput]`.
- Tab titles — both notebooks' `Font` matches `gFonts[dcfTabs]`; tab height accommodates the font (no clipped caption).
- App round-trip — `SaveXmlConfig` then `LoadXmlConfig` against a temp config preserves `dcfInput`/`dcfTabs`, writes `ConfigVersion` 17, and emits `Fonts/Input` + `Fonts/Tabs` nodes.
- Old-config fallback — loading a config XML lacking the new nodes yields the spec defaults with no error.

Revert clause: any Tier-4 check that can't be made to run reliably headless drops to a manual step, noted in `plan.md`.

Status (implemented): Tier 4 reverted to manual. Driving the real `SaveXmlConfig`/`LoadXmlConfig` requires the full global state, and `LoadGlobs` headless raises an access violation in unrelated global init (`uexts` Clear) — it depends on the app's complete boot sequence, not just config. Booting `TfrmMain` headless faces the same/worse (it also needs the embedded `dmhigh.json` HIGHLIGHTERS resource). Coverage instead: the config primitive is covered by Tier 1 (round-trip / default fallback / style bitmask / stream round-trip), `ConfigVersion = 17` by Tier 2, and the command-line / tab-title surfaces by the manual screenshot pass. See notes.md.

## Build gate

Full app compiles with the new enum values, options rows, and apply sites — enforced by the build (CI / build script), not an fpcunit case.

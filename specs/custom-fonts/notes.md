# Custom Fonts — Implementation Notes

Status: implemented; manual verification pass pending.

## What landed

Production wiring (mirrors `dcfSearchResults` / `dcfPathEdit` end to end):
- `uglobs.pas` — `dcfInput` / `dcfTabs` enum values, defaults, `Fonts/Input` +
  `Fonts/Tabs` XML load/save, `ConfigVersion` 16 → 17, lifted `cMonoFonts` to
  unit-visible `DCMonoFonts` (includes `dcfInput`).
- `ulng.pas` — `rsFontUsageInput` / `rsFontUsageTabs` + `Usage` wiring.
- `foptionsfonts.pas` — picker uses `DCMonoFonts`; rows auto-surface via enum iteration.
- Apply sites — MkDir combo, multi-rename edits + preview grid, quick-search edit,
  command line (`dcfInput`); both file-view notebooks (`dcfTabs`).

Tests:
- Tier 1 (console fpcunit, `components/doublecmd/test/dcxmlconfigtests`): 4 tests, green.
- Tier 2 + 3 (GUI fpcunit, `src/dcfonttests`): 7 tests, green — uGlobs constants,
  Options page rows, MkDir, multi-rename, quick search.

## Deviations from plan

- Tier 2 moved from the console project to the GUI project. It asserts `uGlobs`
  constants (`DCMonoFonts`, `ConfigVersion`), and `uGlobs` pulls in the LCL — it
  can't link in a console-only runner. Folded into the GUI suite instead.

- Multi-rename input-font apply moved to the **start** of `FormCreate` (was the
  end). The later init (preset load, menu build) can fail when run headless and
  the LCL swallows the exception, leaving fonts unset. Applying first makes the
  wiring robust regardless of later init order; no production behaviour change.

- GUI runner sets `AppNoExceptionMessages` so headless exceptions surface as
  fpcunit failures rather than modal OK/Abort dialogs.

- Tier 4 reverted to manual (per the revert clause). `LoadGlobs` headless raises
  an access violation in `uexts` Clear — the real `SaveXmlConfig`/`LoadXmlConfig`
  need the app's full boot sequence, not just a config object. `TfrmMain` boot
  faces the same plus the missing embedded `dmhigh.json` resource. The config
  round-trip is covered by Tier 1 (primitive) + Tier 2 (`ConfigVersion`); the
  command-line and tab-title surfaces move to the manual screenshot pass.

## Build gate

Full app: Debug mode builds and links clean with all changes (273k lines).
Release mode is unrelated to this change — it trips a non-deterministic FPC
internal-compiler-error in the optimizer (different untouched file each run);
Debug is the working configuration in this environment.

## Manual verification still owed (Tier 4 + spec "Verification" section)

Dark mode, JetBrains Mono set on both new categories — confirm and screenshot:
- Command line (`edtCommand`) uses the input font.
- Folder-tab titles use the tab font; tab height grows, captions not clipped.
- Multi-rename preview grid rows not clipped by a larger font.

## Follow-ups noticed

- Language `.po` files not touched — the English resourcestrings in `ulng.pas`
  are the fallback; translations regenerate via the existing i18n flow.
- `src/dcfonttests` recompiles the app into the shared `units/` dir on first
  build (build options differ slightly from `doublecmd.lpi`); harmless but means
  a subsequent `doublecmd` build may recompile once.

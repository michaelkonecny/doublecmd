# Font Settings — Spec

Status: agreed
Last updated: 2026-06-15

## Goal
Fonts are organised in a two-level hierarchy by what the text *represents*, not by the widget it sits in. Categories hold real fonts; subcategories either inherit their category's font or carry an explicit override. Font size changes only through the Options → Fonts page.

## Guiding principle
Choose the font by the meaning of the text:
- App's own words (labels, captions) → UI/Chrome.
- User's filesystem data (names, paths, size, date) → Filesystem — even when editable (inline rename).
- User's typed parameters (search text, rename mask) → User input — excluding purely numeric fields. 
- File contents read/written → Document.
- Command output → Console.

## Hierarchy

### UI / Chrome
Role: general non-editable labels (dialog labels, group captions).
Subcategories: Status bar; Function (F-key) buttons; Folder tabs; Tree / menu (drive tree, dir hotlist, tree-view menu).

### Filesystem
Role: file-panel list — names, size, date, path text.
Subcategories: Path / address bar; Inline rename; Search-results list.

### User input
Role: typed parameters (search string, rename mask, mkdir name, command line).
Notes:
- Single flat font, no subcategories.
- Excludes purely numeric fields (multi-rename counter `edPoc`, `edInterval`).

### Document
Role: file contents being read/written.
Subcategories: Editor; Viewer; Viewer book mode (independent default — book typography differs from plain viewer; does not inherit Viewer).

### Console
Role: command-output console.
Subcategory: Log window.

## Inheritance model

Function: a subcategory resolves to its parent category's font unless it carries an explicit override.

Holds:
- `Inherit: Boolean` field on `TDCFontOptions`.
- Resolver: `if Inherit then use parent-category font else use own values`.
- Categories never inherit (no parent); always hold a concrete font.
- Override is whole-font (name + size + style + quality), never per-attribute. Inherit takes the entire parent font.

Notes:
- Resolution happens at apply time (`FontOptionsToFont` site), so changing a category re-flows all inheriting subcategories.

## Zoom

Function: font size changes only via the Options → Fonts page.

Holds:
- No Ctrl+Wheel font zoom anywhere (file panel, editor, viewer, find results, function buttons, tree-view menu, fonts-page preview).
- No `gZoomWithCtrlWheel` setting and no Mouse-control option for it.
- No `cm_MainFontZoomIn` / `cm_MainFontZoomOut` commands and no default hotkeys bound to them.

Notes:
- Commands are gone entirely, not kept as no-ops; document in changelog.
- Users with custom hotkeys bound to the zoom commands lose those bindings.

## Picker UI (Options → Fonts)

Role: indented flat list (no tree control); subcategory rows indented under their category row.

Holds:
- Category row: name preview (`TEdit`, read-only), size `TSpinEdit`, "..." `TFontDialog` button.
- Subcategory row: same controls plus an "Inherit" checkbox. When checked, controls show resolved parent values, greyed/disabled. Unchecking enables them and seeds from the current resolved value.
- Monospace constraint (`fdFixedPitchOnly`) on Document (+subs), Console (+Log), User input.
- Unconstrained picker on display categories (UI, Filesystem).

## Slots

Each slot maps to one font in the hierarchy. Slots with a prior font are explicit overrides; genuinely new slots start at inherit or default.

| Slot | Hierarchy position | Initial state |
|---|---|---|
| Main file panel | Filesystem (category) | explicit |
| Path / address bar | Filesystem ▸ Path/address bar | explicit |
| Inline rename | Filesystem ▸ Inline rename | inherit |
| Search results | Filesystem ▸ Search results | explicit |
| Editor | Document ▸ Editor | explicit |
| Viewer | Document ▸ Viewer | explicit |
| Viewer book | Document ▸ Viewer book | explicit |
| Console | Console (category) | explicit |
| Log window | Console ▸ Log window | explicit |
| User input | User input | explicit |
| Function buttons | UI ▸ Function buttons | explicit |
| Tree / menu | UI ▸ Tree/menu | explicit |
| Status bar | UI ▸ Status bar | explicit |
| Folder tabs | UI ▸ Folder tabs | explicit |
| UI category root | UI (category) | default (system font) |
| Document category root | Document (category) | default (mono) |

Notes:
- UI and Document category roots have no single legacy source. UI root defaults to the system font; Document root defaults to mono.
- Inline rename has no dedicated legacy font; it starts inherit (resolving to Filesystem).

## XML / config

Holds:
- Nodes nest under `Fonts/` mirroring the categories, e.g. `Fonts/Filesystem`, `Fonts/Filesystem/PathEdit`, `Fonts/Document/Editor`.
- Each node stores name/size/style/quality; subcategory nodes also store the `Inherit` flag.
- `ConfigVersion` is 18.

Migration (one-time, gated on `ConfigVersion < 18`):
- Old flat nodes (`Fonts/Main`, `Fonts/PathEdit`, …) seed the new tree per Slots.
- Every seeded slot with a prior font becomes an explicit override → existing look preserved exactly.
- Slots with no prior node start at default (category) or inherit (subcategory).

## Edge cases
- Old config missing some nodes → that slot starts at default (category) or inherit (subcategory).
- Subcategory set explicit then re-checked Inherit → stored values discarded on save; resolved value re-derives from parent.
- Category font changed → all inheriting subcategories re-flow on next apply; live repaint of panels, tabs, status bar.
- Status bar / search-results row height with larger fonts → no clipping (carried over from custom-fonts spec).

## Non-goals
- Per-attribute inheritance (inherit only size, override name) — whole-font inherit only.
- Per-control fonts beyond the listed slots.
- New user-input subcategories.
- Ctrl+Wheel zoom in any form.

## Verification
Automated where possible:
- Config-migration test: old XML → expected new tree with correct explicit/inherit flags.
- Resolver unit test: subcategory inherit vs override.

Manual/screenshot pass in dark mode with a monospaced font across all categories after implementation.

# fork-win-installer — Spec

Status: draft
Last updated: 2026-07-28

## Goal

Keep a downloadable Windows installer of this fork's `master` in GitHub, built automatically, without ever adding fork-specific files to `master` — so pull requests from `michaelkonecny/doublecmd` to `doublecmd/doublecmd` contain only real source changes.

## Non-goals

- No macOS or Linux builds. Windows x86_64 only.
- No i386 build.
- No `.7z` portable, `.msi`, or `.zip` package — installer only.
- No signing of the installer.
- No changes to upstream's `snapshots.yml`, `release.yml`, `winget.yml`, or anything under `.github/scripts/`.
- No GitHub Release objects, no publishing to `doublecmd/snapshots`.
- Not push-triggered. See Why cron, not push.

## Branch topology

Role: keep all fork-only CI on a branch that shares no history with `master`, so nothing can flow between them.

- `master` — tracks upstream, carries only work intended for upstream PRs. Never contains this spec, this workflow, or any reference to them. Must exist on the fork's remote: it is the only ref this CI ever builds, and the fork having no `master` is a hard error rather than a no-op.
- `fork-ci` — orphan branch (no common ancestor with `master`), holds exactly three files: this spec, `.github/workflows/fork-win-installer.yml`, and a short `README.md`. Set as the fork's default branch.
- Never merged in either direction. The workflow reaches `master` by checking it out at build time, not by sharing history.

Consequence of `fork-ci` being the default branch: the fork's GitHub landing page shows the CI branch, and a fresh `git clone` of the fork lands on `fork-ci`. Both accepted. PRs to upstream are unaffected — GitHub bases a fork PR on the *upstream* repo's default branch.

## Why cron, not push

A `push` trigger only fires for workflow files present on the pushed ref, so "build on every master push" would force this file onto `master` — the thing the whole design avoids. Scheduled workflows, by contrast, run only from the default branch, which is exactly where this file lives.

Cost accepted: up to ~2 h latency between a `master` push and its installer, plus GitHub's best-effort cron delays under load.

## Trigger and deduplication

- `schedule`: every 2 hours.
- `workflow_dispatch`: manual, with a boolean `force` input that bypasses deduplication.
- Deduplication: a `check` job resolves the current head of `master` via `git ls-remote` (no clone) and looks up an `actions/cache` entry keyed on that SHA. Cache hit and not forced → no build. The `build` job saves the marker on success, so only successful builds suppress later runs.
- Cache eviction (7 days untouched) causes at most a redundant rebuild — acceptable.
- `concurrency` group is fixed, `cancel-in-progress: false`: a running build finishes rather than being killed by the next tick.

## Build

Runner: `windows-latest`.

Steps, mirroring `.github/scripts/create_snapshot.bat` up to the point where it diverges into `.7z` packaging:

1. `doublecmd/lazarus-install@win`, `lazarus-version: stable`.
2. Checkout `master` pinned to the SHA the `check` job resolved, `fetch-depth: 0` — full history is required, since the revision number is `git rev-list --count HEAD`.
3. `chetan/git-restore-mtime-action@v2`.
4. Download `windows.7z` from `doublecmd/external` into `install/`, extract, delete the archive.
5. Read version from `src/doublecmd.lpi`; run `src/platform/git2revisioninc.exe.cmd` for the revision; export `DC_VER` and `REVISION` via `GITHUB_ENV`.
6. `build.bat darkwin` with `CPU_TARGET=x86_64`, `OS_TARGET=win64`; copy the DLLs, `winpty-agent.exe`, and any `*.sfx` from `install/windows/lib/x86_64/` next to the binary.
7. Ensure Inno Setup and every translation `doublecmd.iss` asks for are present — see Inno Setup.
8. `install/windows/install.bat` populates `%BUILD_PACK_DIR%\doublecmd`, the tree `doublecmd.iss` packs.
9. Copy `doublecmd.iss` next to that tree and run `ISCC` with `/F"doublecmd-<DC_VER>.r<REVISION>.x86_64-win64"` and `/DDisplayVersion=<DC_VER>`.
10. Move the `.exe` plus a 10-entry `changelog.txt` into `out/`.

Installer logic is inlined in the workflow rather than added as a `.github/scripts/*.bat` file, so the fork-only footprint on the build side is exactly one file.

### Inno Setup

`ISCC.exe` is expected at `%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe`; if absent, the workflow installs it with `choco install innosetup -y --no-progress`. This covers both current runner images — `windows-2022` ships Inno Setup 6.4.0, `windows-2025` ships none — and survives future image changes without edits.

`install/windows/doublecmd.iss` is documented as an Inno Setup 5 script; 6.7.1 parses it (the deprecated `{pf}` constant is still accepted).

Its `[Languages]` block names 26 translations, four of which Inno Setup does not bundle — Greek, Nepali, SerbianCyrillic, SerbianLatin — and a missing one is a hard compile error, not a warning. Upstream's build machine has them installed by hand; a clean runner does not. The workflow therefore parses the `compiler:Languages\*.isl[u]` references out of `doublecmd.iss` and fetches whatever is absent from `jrsoftware/issrc` under `Files/Languages/Unofficial`. Derived from the script rather than hardcoded, so upstream adding a 27th language cannot break the build.

`doublecmd.iss` itself is never patched — that would put a fork-only change on `master`.

### Failure detection

`shell: cmd` steps report only the last command's exit code, so intermediate failures are silent by default. Every step therefore asserts explicitly: `if errorlevel 1 exit /b 1` after fallible commands, plus existence checks on `doublecmd.exe`, on the populated install tree, and on the moved `.exe`.

`>>%GITHUB_ENV% echo VAR=%VALUE%` puts the redirection first on purpose: written the natural way, a value ending in a digit makes `cmd` read that digit as a stream handle.

## Output

- One artifact per build, named `doublecmd-win64-r<REVISION>-<short-sha>`, holding the installer `.exe` and `changelog.txt`.
- `retention-days: 90` — GitHub's maximum, and the retention we want.
- `compression-level: 0`; the installer is already LZMA-compressed.
- Download requires a GitHub login. Accepted; the alternative (Releases, publicly downloadable) was rejected to avoid permanent clutter in the fork.

## Permissions and secrets

- `permissions: contents: read`. Artifacts need nothing more; the implicit `GITHUB_TOKEN` covers the checkout of this public fork.
- No repository secrets, no PAT, no environment. Upstream's `upload` job depends on `secrets.SNAPSHOTS`, environment `snapshots`, and `vars.BODY`, none of which exist here — which is why none of it is reused.

## One-time manual setup

Ordered; steps 2 and 3 gate everything after them.

1. Push `fork-ci` to `origin`.
2. Repo Settings → General → Default branch → `fork-ci`.
3. Actions tab → enable Actions for the fork. GitHub disables scheduled workflows in forks by default; `workflow_dispatch` is also unavailable until the workflow file is on the default branch.
4. Run `fork-win-installer` manually with `force: true` to verify.

Ongoing: a public repository has its scheduled workflows auto-disabled after 60 days without repository activity. Regular pushes to `master` count as activity, so this only bites if the fork goes quiet.

## PR hygiene

The topology makes leaking the CI setup into a PR structurally impossible rather than a matter of discipline: the files exist only on a branch that never merges into `master`. The remaining rule is the ordinary one for any fork — base PR branches on `upstream/master`, not on a diverged local `master`.

## Edge cases

- Fork has no `refs/heads/master` → `check` job fails with an explicit `::error::`, not a bare exit code.
- `master` unchanged since the last successful build → `check` job reports the skip in the run summary, `build` job does not start.
- Cache marker evicted → one redundant rebuild, same artifact content.
- Build fails → no marker saved, so the next tick retries the same SHA.
- Two ticks overlap → the second queues behind the first; it is not cancelled.
- `master` moves while a build runs → irrelevant; the build is pinned to the SHA resolved at its start. The newer commit is picked up by the next tick.
- `git2revisioninc.exe.cmd` fails to produce a revision → step exits non-zero rather than building an unlabelled installer.
- Inno Setup missing from the runner image → installed via Chocolatey.

## Follow-ups

- Consider tightening the cron once real build duration is known. First observed timing: Lazarus install through a finished x86_64 build in roughly 4 minutes.
- Consider adding the `.7z` portable if a no-install build turns out to be wanted.

## Out of scope

- Signing, notarization, winget publication.
- Building PR branches or any ref other than `master`.
- Mirroring upstream's multi-platform snapshot matrix.

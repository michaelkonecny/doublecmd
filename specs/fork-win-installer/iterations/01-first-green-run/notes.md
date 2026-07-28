# 01 — first green run

Implementation notes for the initial build-out of `fork-win-installer`. Decisions, deviations from
the spec, and things learned from real runs.

## Decisions

Topology — orphan `fork-ci` branch, cron-triggered, rather than a workflow on `master`.
- A `push` trigger only fires for workflow files present on the pushed ref, so push-triggered builds
  would force fork-only files onto `master`.
- Scheduled workflows run only from the default branch, so `fork-ci` is the fork's default branch.
- Orphan (no common ancestor with `master`) means the two branches never merge in either direction,
  making a leak into an upstream PR structurally impossible rather than a matter of discipline.

Output — workflow artifacts at 90 days, not Releases.
- 90 days is the artifact maximum and the retention asked for.
- Releases would be permanent and publicly downloadable, at the cost of permanent clutter in the
  fork. Rejected on that trade.

Scope — x86_64 installer only.
- Halves runner time against upstream's dual-arch snapshot. No i386, no `.7z`, no `.msi`.

Installer logic inlined in the workflow, not added as `.github/scripts/*.bat`.
- Keeps the fork-only footprint on the build side to exactly one file.

`doublecmd.iss` is never patched.
- Any fix must live in the workflow on `fork-ci`. Patching the script would put a fork-only change on
  `master`, which is the thing this design exists to prevent.

## Findings from real runs

Fork had no `refs/heads/master`.
- `master` had previously been renamed to `fork-ci` on the remote, so the fork's only branch carried
  the font-settings work under the CI branch's name.
- Runs 1 and 2 failed in `check` because `git ls-remote … refs/heads/master` returned empty.
- `master` was restored from the local branch; the fork now has both refs.

Inno Setup on `windows-latest`.
- Server 2025 ships none; `choco install innosetup` yields 6.7.1.
- 6.7.1 parses this Inno-5-era script, deprecated `{pf}` included.

`doublecmd.iss` needs four unofficial translations.
- Greek, Nepali, SerbianCyrillic, SerbianLatin are distributed separately from the compiler, and a
  missing `.isl` is a hard compile error.
- Upstream never hits this: `create_snapshot.bat` builds only `.7z`, and the installer path in
  `create_packages.bat` has only ever run on a dev box that has the files installed.
- Fetched from `jrsoftware/issrc` under `Files/Languages/Unofficial`, resolved from the script's own
  `[Languages]` block rather than hardcoded.

Timing — Lazarus install through a finished x86_64 build: roughly 4 minutes.

Caches do not cross operating systems.
- Run 3 logged `Cache saved with key: fork-win-installer-d7930a68…` from the Windows build job; run 4
  logged `Cache not found for input keys:` with a byte-identical key from the Linux check job.
- The restore log spelled out the cause: `enableCrossOsArchive: false`.
- Failure mode is silent and expensive: dedup never hits, so every cron tick rebuilds. Caught only
  because a no-force dispatch was run deliberately to test the skip path.
- Fixed by setting `enableCrossOsArchive: true` on both the save and the restore.
- Alternatives considered: run `check` on Windows too (wasteful, slower startup), or replace the
  cache with an Actions API query for an existing artifact of that SHA (more robust, but the artifact
  name embeds the revision number that only the build job computes, so it would need suffix matching
  and paging). The documented one-flag fix won on size.

`shell: cmd` hides intermediate failures.
- Only the last command's exit code reaches Actions, so every fallible command is followed by an
  explicit `if errorlevel 1 exit /b 1`, plus existence assertions on the built binary, the populated
  install tree, and the moved `.exe`.

## Incident — force-push over `fork-ci`

The remote already had a `fork-ci` branch. It was compared against the local `origin/master` tracking
ref, matched exactly, and was read as a redundant copy of `master`; it was then force-pushed over.

It was not a copy. `master` had been renamed to `fork-ci`, so the two names referred to one branch and
`origin/master` was a stale ref for a branch that no longer existed remotely. No commits were lost —
all of them were present in the local clone — and `master` was pushed back to the fork.

Lesson: verify remote state with `git ls-remote --heads`, not with local remote-tracking refs. Local
refs can describe a remote that has since changed.

## AFK log

Autonomous decisions taken while the user was away, newest last.

- 19:36 — Chose this file as the decision log, under `iterations/01-first-green-run/`, matching the
  layout the spec skill documents. Alternative was an ad-hoc log outside the repo; rejected as less
  discoverable.

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

## Upstream's snapshots.yml is live in the fork

Not part of this feature, but discovered while diagnosing and it affects everyday work on the fork.

- `snapshots.yml` came with the fork and is registered and `active` (workflow id 322277416).
- It triggers on pushes to `master` touching `components/`, `plugins/`, `sdk/` or `src/`, so it fires
  on ordinary work. Two runs exist, both failed: one at 15:10Z predating this session, one at 17:26Z
  caused by pushing `master` back to the fork.
- It cannot succeed here: the `upload` job wants `secrets.SNAPSHOTS`, environment `snapshots` and
  `vars.BODY`, none of which exist in the fork. The three build jobs do succeed first, so each push
  spends a full multi-platform build before failing at the last step.
- Left alone deliberately. Disabling it is one reversible API call and would stop the noise, but the
  build jobs do produce mac and Linux artifacts that may be worth having. That trade is the user's to
  make, not something to decide unattended.

## Verification

Build path — run `30383476379`, green end to end.
- Artifact `doublecmd-win64-r13118-d7930a68`, 11.7 MB, expiry 90 days out.
- Contents: `doublecmd-1.3.0.r13118.x86_64-win64.exe` (12,277,103 bytes) and `changelog.txt`.
- The `.exe` is a real PE carrying an Inno Setup payload, with `Double Commander`, `1.3.0` and
  `Alexander Koblov` present as UTF-16 strings. Revision and short SHA both match `master`.
- Not installed locally: silent installation would leave uninstall registry entries and Start Menu
  icons on the developer's machine. Signature and string checks were judged sufficient.

Skip path — run `30384672030`, dispatched without `force` after a successful build of the same SHA.
- `Cache hit for: fork-win-installer-d7930a682e…`, condition evaluated as `[ "true" = "true" ] &&
  [ "false" != "true" ]`, summary line written, `build` job reported `skipped`.

Cron trigger — not yet observed.
- The 18:00Z tick did not fire; at 18:52Z the repository had nine runs, all `workflow_dispatch`.
- Ruled out: workflow `state` is `active`, repo Actions `enabled` with `allowed_actions: all`, the
  file is on the default branch, the repo is public. The idempotent workflow-enable endpoint was
  called anyway to close off the fork-disables-schedules hypothesis.
- Most likely benign: the workflow was created 17:13Z, and a newly registered cron can take from
  15 minutes to over an hour to be recognised — the 18:00Z tick fell 46 minutes after creation,
  inside that window.
- Minute 0 is also the worst slot to have picked; it is the most contended in GitHub's scheduler.
- Actions taken: moved to minute 37, plus a temporary `*/10` schedule so the trigger gets several
  chances to prove itself within the hour instead of one chance every two hours. The temporary entry
  must be removed once a `schedule` run has been seen.
- Second window also missed: the probe was pushed 18:54Z and ticks at 19:00Z, 19:10Z and 19:20Z all
  produced nothing. Workflow still reads `state: active`, so the fork-disable was never in effect.
- What the docs actually say: "When a public repository is forked, scheduled workflows are disabled
  by default", remedied by the Enable workflow button or `gh workflow enable` — i.e. the
  `PUT /actions/workflows/{id}/enable` endpoint already called here. Also confirmed: "The schedule
  event can be delayed during periods of high loads... High load times include the start of every
  hour", and 60 days of inactivity auto-disables schedules in public repos.
- Standing hypothesis: registration lag. The schedule was last updated 18:54Z and the documented lag
  reaches an hour, so nothing before ~19:54Z is conclusive.
- If it still has not fired well past that, cron in a fork should be treated as unavailable in
  practice, and the trigger needs rethinking — see Open question.

## Open question — what if cron never fires here

Only the user can settle this, since every remaining option changes something they chose.

- A standalone repository (not a fork) holding the scheduler is the only cron-capable variant, since
  the fork restriction would not apply to it. This was offered and rejected in favour of `fork-ci`;
  if forks genuinely cannot run schedules, that rejection rested on a false premise.
- Push-triggered on `master` would work but puts the workflow on `master`, defeating the whole point.
- Manual `workflow_dispatch` only, which is verified working, plus a local `pre-push` hook that fires
  the dispatch. Keeps `master` clean at the cost of a token on the developer's machine.
- Creating a repository is outward-facing, so it was not done unattended.

## AFK log

Autonomous decisions taken while the user was away, newest last.

- 19:36 — Chose this file as the decision log, under `iterations/01-first-green-run/`, matching the
  layout the spec skill documents. Alternative was an ad-hoc log outside the repo; rejected as less
  discoverable.
- 19:39 — Declined to run the built installer on the developer's machine to verify it, unattended.
  See Verification for what was checked instead.
- 19:47 — Chose `enableCrossOsArchive` over moving `check` to Windows or replacing the cache with an
  artifact-existence query. See the cross-OS finding for the reasoning.
- 19:52 — Left the spec at `Status: draft`. Only the user approves a spec; the design is verified but
  approval is not mine to grant.
- 19:53 — Decided to stay up past the stated window for the cron tick, since the production trigger
  is the one thing manual dispatches cannot exercise. (Tick time was misstated as 20:00Z in chat;
  local is UTC+2, so the tick to watch was 18:00Z.)
- 20:55 — Added a temporary `*/10` schedule rather than waiting two hours per attempt. Reversible,
  and each tick skips the build so it costs seconds. Judged better than leaving the production
  trigger unverified.

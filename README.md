# fork-ci

CI branch of the `michaelkonecny/doublecmd` fork. Orphan branch — shares no history with `master`
and is never merged into it, so fork-only tooling can never appear in a pull request to
`doublecmd/doublecmd`.

Holds:

- `.github/workflows/fork-win-installer.yml` — builds a Windows x86_64 installer from `master` on a
  schedule and keeps it as a workflow artifact.
- `specs/fork-win-installer/spec.md` — the design, including the one-time repository setup.
- `specs/fork-win-installer/iterations/01-first-green-run/notes.md` — decisions, findings from real
  runs, and open questions.

The actual Double Commander source is on [`master`](../../tree/master).

## Starting a build

Browser — [fork-win-installer](../../actions/workflows/fork-win-installer.yml) → Run workflow →
branch `fork-ci` → Run. Takes about five minutes.

The `ref` is `fork-ci`, not `master`: it selects which branch's *workflow file* runs, and the workflow
checks out `master` itself.

Command line, with a token carrying `Actions: write` on this repository:

```sh
curl -X POST \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/michaelkonecny/doublecmd/actions/workflows/322369044/dispatches \
  -d '{"ref":"fork-ci","inputs":{"force":"true"}}'
```

HTTP 204 and an empty body means it started.

The `force` input only defeats deduplication. A commit that already built successfully is skipped, so
`force` is for rebuilding the same commit; after pushing to `master` a plain run with no inputs
builds it.

Scheduled runs fire from the cron in the workflow. As of the first build-out the schedule had never
actually fired — see the notes — so treat a manual run as the reliable path until that is settled.

## Getting the installer

Open the run from the [workflow's run list](../../actions/workflows/fork-win-installer.yml) and use
the Artifacts box at the bottom of the run summary. Each successful build leaves one artifact named
`doublecmd-win64-r<revision>-<short-sha>`, holding:

- `doublecmd-<version>.r<revision>.x86_64-win64.exe` — the Inno Setup installer, around 12 MB.
- `changelog.txt` — the last ten commits of `master`.

Notes:

- Artifacts are kept 90 days, GitHub's maximum, then deleted.
- Downloading requires being signed in; artifacts are not public even on a public repository. That is
  the trade made against publishing Releases, which would be public but permanent clutter.
- GitHub wraps every artifact download in a `.zip`, so the `.exe` arrives inside an archive.

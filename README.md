# fork-ci

CI branch of the `michaelkonecny/doublecmd` fork. Orphan branch — shares no history with `master`
and is never merged into it, so fork-only tooling can never appear in a pull request to
`doublecmd/doublecmd`.

Holds:

- `.github/workflows/fork-win-installer.yml` — builds a Windows x86_64 installer from `master` on a
  schedule and keeps it as a workflow artifact.
- `specs/fork-win-installer/spec.md` — the design, including the one-time repository setup.

The actual Double Commander source is on [`master`](../../tree/master).

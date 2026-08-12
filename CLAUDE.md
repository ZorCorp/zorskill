# zorskill — repo guidance

Plugin collection for the `ZorCorp` Claude Code marketplace. Each plugin lives under `plugins/<name>/`.

---

## Releasing a plugin (ref-pinned url sources — since marketplace 1.3.0)

Every `marketplace.json` entry is a remote source pinned to its release tag:
`{"source":"url","url":"https://github.com/ZorCorp/<name>.git","ref":"v<version>"}` — users install
the TAG over HTTPS, so nothing depends on submodules (`/plugin marketplace add` and claude.ai org
sync never init them) or on SSH keys (the `{"source":"github"}` form clones over SSH — avoid it).
Invariant, tool-enforced: `source.ref == "v" + version`. The `plugins/<name>/` submodules remain as
maintainer scaffolding (local editing, audits) — consumers never touch them.

1. Edit the plugin in `plugins/<name>/`; commit + push to `ZorCorp/<name>`. Cut its release with the
   plugin repo's own workflow: `gh workflow run release.yml -f version=<x.y.z>` (bumps
   `.claude-plugin/plugin.json`, commits, tags `v<x.y.z>`).
2. `/zorskill-dev:release <name> <x.y.z>` — verifies tag `v<x.y.z>` exists and declares `<x.y.z>`,
   advances the entry's `version` + `source.ref` together (and the on-disk submodule checkout,
   best-effort), syncs the aggregate `.version` + README, runs `check`, and commits to zorskill.
   (Or just wait — the drift Action carries tagged releases in automatically within ~30 min.)
3. Review, then `git push origin main`.
4. `/zorskill-dev:mirror mcailab/zorskill-org` — copy the manifest to the PRIVATE org-sync companion
   repo (claude.ai "Sync from GitHub" requires a private repo; the org marketplace syncs from there).

Audit anytime with `/zorskill-dev:check`. Scaffold a new plugin with `/zorskill-dev:new <name>`.

For **marketplace releases**, `zorskill-dev` is the generalized, team-facing successor to the
kf-cli-specific `scripts/kf-cli-release.sh` + personal `kf-cli-dev` skill; prefer `/zorskill-dev:*`.
Those older tools still exist and their broader retirement is a separate, in-progress cleanup — don't
assume they're gone yet.

**Not covered here:** kf-cli's standalone Agent-Skill distribution (the `ZorCorp/kf-cli` mirror for
`npx skills` / `install.sh`) is a separate concern with its own runbook. In particular, `npx skills
add/update` installs only `SKILL.md` and drops `commands/`+`templates/`, so use `install.sh` there —
`zorskill-dev` does not manage that mirror.

# zorskill — repo guidance

Plugin collection for the `ZorCorp` Claude Code marketplace. Each plugin lives under `plugins/<name>/`.

---

## Releasing a plugin (uniform submodule model)

Every plugin under `plugins/<name>/` is a git submodule pointing at `ZorCorp/<name>`.
The `zorskill-dev` plugin automates the aggregation-side release chore.

1. Edit the plugin in `plugins/<name>/`; commit + push to `ZorCorp/<name>`, bumping its
   `.claude-plugin/plugin.json` `.version`.
2. `/zorskill-dev:release <name> <x.y.z>` — advances the submodule pointer, verifies the plugin
   repo declares `<x.y.z>`, syncs the root `marketplace.json` (per-plugin entry + top-level aggregate
   `.version`), runs `check`, and commits to zorskill.
3. Review, then `git push origin main`.

Audit anytime with `/zorskill-dev:check`. Scaffold a new plugin with `/zorskill-dev:new <name>`.

For **marketplace releases**, `zorskill-dev` is the generalized, team-facing successor to the
kf-cli-specific `scripts/kf-cli-release.sh` + personal `kf-cli-dev` skill; prefer `/zorskill-dev:*`.
Those older tools still exist and their broader retirement is a separate, in-progress cleanup — don't
assume they're gone yet.

**Not covered here:** kf-cli's standalone Agent-Skill distribution (the `ZorCorp/kf-cli` mirror for
`npx skills` / `install.sh`) is a separate concern with its own runbook. In particular, `npx skills
add/update` installs only `SKILL.md` and drops `commands/`+`templates/`, so use `install.sh` there —
`zorskill-dev` does not manage that mirror.

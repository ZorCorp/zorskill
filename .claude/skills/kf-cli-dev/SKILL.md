---
name: kf-cli-dev
description: "Maintainer skill for developing and releasing the kf-cli plugin from THIS zorskill repo. Use whenever the user is editing kf-cli under plugins/kf-cli/ and wants to check, version-bump, or release it — it runs one command that bumps all version files, audits, pushes both the canonical (zorskill) and mirror (ZorCorp/kf-cli) repos, and refreshes downstream agent installs. Triggers: 'release kf-cli', 'update kf-cli version', 'bump kf-cli', 'sync kf-cli to the mirror', 'ship kf-cli'."
metadata:
  version: "1.0.0"
  scope: this-repo-only
---

# kf-cli-dev — release & housekeeping for kf-cli

This is a **maintainer-only** skill that lives in the zorskill repo (`.claude/skills/kf-cli-dev/`).
It is auto-available whenever you work anywhere inside this repo. It is **not** published to the
marketplace. Everything it does is driven by one portable script:

```
scripts/kf-cli-release.sh
```

The script derives its own paths (`git rev-parse`-style, from its location) and finds-or-clones the
mirror on demand — so it works on any machine that has this repo, with **no hardcoded paths and no
required `kf-cli-sync` folder.**

## The model (why two repos)

- **CANONICAL — source of truth:** `plugins/kf-cli/` in THIS repo (`ZorCorp/zorskill`). Claude Code
  installs kf-cli from the zorskill marketplace. **You only ever edit here.**
- **MIRROR:** `ZorCorp/kf-cli` (standalone) — what non-Claude agents install via `npx skills` /
  `install.sh`. It is synced FROM canonical. **Never hand-edit it.**

## How to use it

**1. Edit** kf-cli in `plugins/kf-cli/` (commands, templates, SKILL.md, etc.).

**2. Check status any time:**
```bash
scripts/kf-cli-release.sh status     # versions across all 5 spots + is the mirror behind?
scripts/kf-cli-release.sh check       # full audit: version consistency, JSON, strict-YAML SKILL.md, identity-free
```

**3. Release in ONE command** (this replaces the old 8-step checklist):
```bash
scripts/kf-cli-release.sh release <x.y.z> "one-line changelog note"
```
That single command:
1. Bumps the version in **all 5 spots** (plugin.json · plugin marketplace.json · **root marketplace.json** · SKILL.md · CHANGELOG).
2. Runs `check` — **aborts** if anything fails (version drift, invalid JSON, unquoted SKILL.md YAML, identity/model leak).
3. Commits + pushes **canonical** (`main`).
4. Syncs shared content → the **mirror** (find-or-clone), commits + pushes it (`master`).
5. **Refreshes agents** (`install.sh --update` → `~/.agents/skills/kf-cli`) and prints a `/reload-plugins` reminder for Claude Code.

Flags: `--no-push` (do everything locally, push manually) · `--no-refresh` (skip agent update).

**Semver:** new command/template/capability → minor (`0.8.0`); fix/docs → patch (`0.7.2`).

## Rules (do not deviate)

- **Never** edit version numbers by hand, and **never** edit the mirror repo directly — `release` owns both.
- **Never** `git add -A` in canonical for a release — the script stages only `plugins/kf-cli` + the root `marketplace.json`.
- If `check` fails after a bump, the files are already changed — fix the ✗ item and re-run `check`, or `git checkout` to revert, before pushing.
- The **root `marketplace.json`** version is the one that silently drifts (it's the manifest Claude Code reads). `check` now enforces it; keep it in the loop.
- **SKILL.md frontmatter must be strict-YAML valid** — scalar values containing `: ` (like `Commands: /capture`) must be quoted, or `npx skills` can't install the skill. `check` guards this.

## After a release

- **Claude Code** picks up the new version after you run `/reload-plugins` (or `/plugin marketplace update zorskill`).
- **Agents** (`~/.agents/skills/kf-cli`, Hermes, etc.) get it from the mirror via **`install.sh --update`** (the release step runs this for `~/.agents`).
  ⚠️ **Never use `npx skills` for kf-cli** — it installs only `SKILL.md` and strips `commands/`+`templates/`, breaking `/watch`. Use `install.sh`. For Hermes, copy the full `~/.agents/skills/kf-cli/` tree into its slot (its curator must preserve `commands/`).

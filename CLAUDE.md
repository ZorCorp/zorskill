# zorskill — repo guidance

Plugin collection for the `ZorCorp` Claude Code marketplace. Each plugin lives under `plugins/<name>/`.

---

## Releasing kf-cli (read before changing `plugins/kf-cli/`)

kf-cli is published from **two GitHub repos that must stay in sync**. Forgetting the second one is
the #1 release mistake — a change shipped to only one repo leaves installers serving stale content.

| Repo | Role | Install path | Local clone |
|---|---|---|---|
| **ZorCorp/zorskill** → `plugins/kf-cli/` | **CANONICAL — source of truth.** Claude Code plugin marketplace. | `/plugin install kf-cli` | `~/Dev/zorcorp/zorskill` |
| **ZorCorp/kf-cli** (standalone) | **MIRROR.** Agent Skill for `npx skills add` / `gh skill install`. | npx / gh / install.sh | `~/Dev/zorcorp/kf-cli-sync` |

**Always develop in `plugins/kf-cli/` (canonical), then sync OUT to the standalone repo.** Never edit
the standalone repo directly.

### The tool

`scripts/kf-cli-release.sh` automates the mechanical parts — run from the zorskill repo root:

```bash
scripts/kf-cli-release.sh check      # version consistency + JSON + identity-free audit (canonical)
scripts/kf-cli-release.sh versions   # show versions in BOTH repos; warns if mirror is behind
scripts/kf-cli-release.sh sync       # copy shared content canonical → mirror, bump mirror version
```

### Release checklist

**1. Bump the version in ALL canonical version locations** (the `check` step enforces they match):
- `plugins/kf-cli/.claude-plugin/plugin.json` → `version`
- `plugins/kf-cli/.claude-plugin/marketplace.json` → `metadata.version`
- `plugins/kf-cli/SKILL.md` → frontmatter `metadata.version`
- `plugins/kf-cli/CHANGELOG.md` → new top entry `## [x.y.z] - YYYY-MM-DD`
- **`.claude-plugin/marketplace.json` (repo ROOT)** → the `kf-cli` entry's `version` — ⚠️ this is the manifest Claude Code actually reads to list plugins, but **`check` does NOT audit it**. It silently drifted to `0.5.13` while everything else was `0.7.1`. Update it by hand every release until `check` covers it.

Use semver: new command/template/capability → minor (`0.7.0`); fix/docs/deprecation → patch (`0.7.1`).

**2. When a capability or wording changes, propagate the description to EVERY surface** (easy to miss):
- `plugins/kf-cli/SKILL.md` — frontmatter `description:` **and** the relevant body section
- `plugins/kf-cli/.claude-plugin/plugin.json` — `description`
- `plugins/kf-cli/.claude-plugin/marketplace.json` — `metadata.description` **and** `plugins[].description`
- `plugins/kf-cli/README.md` — intro line + commands table
- `plugins/kf-cli/COMMANDS.md` — quick-reference table, per-command section, routing table
- the changed command's own `commands/<cmd>.md` frontmatter `description:`
- `plugins/kf-cli/commands/setup.md` — the "Available Commands" help echo
- `plugins/kf-cli/templates/vault-skeleton/CLAUDE.md` — the `/capture` routing note (if routing changed)
- If a **command file is added/removed**: update the `commands` array in **both** repos' marketplace.json.

**3. Verify (don't assert — run it):**
```bash
scripts/kf-cli-release.sh check        # must print PASS
```
Then **actually run the changed command end-to-end** (e.g. `/kf-cli:watch <url>` to a written note).
Honesty rule from the skill's own audit: no model names, no hardcoded vault path unpaired with
`KF_VAULT_PATH`, no identity leak (`Zorro`/`Kira`) inside `plugins/kf-cli/`.

**4. Commit + push canonical** (this repo, direct to `main` per convention):
```bash
git add plugins/kf-cli && git commit -m "kf-cli vX.Y.Z: ..." && git push origin main
```

**5. Sync the mirror** (ZorCorp/kf-cli) — do NOT skip:
```bash
scripts/kf-cli-release.sh sync         # copies shared files + bumps mirror marketplace.json
git -C ~/Dev/zorcorp/kf-cli-sync diff  # REVIEW — reconcile any standalone-specific README/install bits
git -C ~/Dev/zorcorp/kf-cli-sync add -A
git -C ~/Dev/zorcorp/kf-cli-sync commit -m "sync from zorskill vX.Y.Z"
git -C ~/Dev/zorcorp/kf-cli-sync push  # default branch is 'master' on this repo
```
`sync` copies the shared content (SKILL.md, README, COMMANDS, CHANGELOG, TROUBLESHOOTING, MIGRATION,
`commands/`, `templates/`, `scripts/`, `hooks/`). Each repo keeps its own `.claude-plugin/`
(canonical has `plugin.json` + `marketplace.json`; mirror has `marketplace.json` only) and `.git/`.

**`install.sh` is MIRROR-OWNED — never synced.** It is the standalone repo's Agent-Skills installer
(symlink/junction auto-link, `--no-link`/`--force-link`/`--uninstall`). The canonical copy under
`plugins/kf-cli/install.sh` is vestigial and stale; Claude Code users install via the marketplace,
not `install.sh`. If you ever improve the installer, do it in the **mirror** repo.

**6. Refresh local installs** — do NOT skip if any non-Claude agent uses kf-cli. `~/.agents/skills/kf-cli/`
and per-tool symlinks update via `npx skills update ZorCorp/kf-cli` or the standalone `install.sh --update`.
Skipping this is exactly why agents (Hermes, `~/.agents`) drift to a stale version and stop matching the
canonical skill — the mirror can be current while the *installed* copy is months old.

### Gotchas learned the hard way
- The canonical `marketplace.json` and `plugin.json` drifted to `0.5.13` while `SKILL.md`/`CHANGELOG`
  were already `0.6.1`. `check` exists precisely to catch this — run it before every push.
- The mirror was missing `templates/meeting-note-template.md` and the whole `hooks/` dir. `sync` now
  carries `hooks/`; review the mirror diff in case the Agent-Skill distribution should omit it.
- Branch names differ: canonical pushes to `main`, the mirror's default is `master`.

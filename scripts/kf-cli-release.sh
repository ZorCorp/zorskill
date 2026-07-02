#!/usr/bin/env bash
# kf-cli-release.sh — release guardrails + one-command release for kf-cli.
#
# kf-cli is published from TWO repos that must stay in sync:
#   • CANONICAL: ZorCorp/zorskill  → plugins/kf-cli/   (Claude Code plugin marketplace)
#   • MIRROR:    ZorCorp/kf-cli     (standalone Agent Skill: npx skills / install.sh)
# zorskill is the source of truth; the standalone repo is synced FROM it.
#
# Usage:
#   scripts/kf-cli-release.sh check                 # consistency + audit + JSON + SKILL.md YAML  (default)
#   scripts/kf-cli-release.sh status               # versions across ALL spots + is mirror behind?
#   scripts/kf-cli-release.sh bump  <x.y.z> "note" # edit the 5 version spots + CHANGELOG (no git)
#   scripts/kf-cli-release.sh sync                 # copy shared content canonical → mirror, bump its version
#   scripts/kf-cli-release.sh release <x.y.z> "note" [--no-push] [--no-refresh]
#         # bump → check → commit+push canonical → sync+commit+push mirror → refresh agents
#
# Env:
#   KF_STANDALONE_DIR   local clone of ZorCorp/kf-cli (optional — otherwise cloned on demand)
#   KF_MIRROR_URL       mirror git URL (default: https://github.com/ZorCorp/kf-cli.git)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # zorskill root (portable; not hardcoded)
KF="$REPO_ROOT/plugins/kf-cli"                                 # canonical plugin
ROOT_MARKET="$REPO_ROOT/.claude-plugin/marketplace.json"      # marketplace manifest (lists all plugins)
MIRROR_URL="${KF_MIRROR_URL:-https://github.com/ZorCorp/kf-cli.git}"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }

canon_version()  { jq -r '.version' "$KF/.claude-plugin/plugin.json"; }
root_kf_version(){ jq -r '(.plugins[]|select(.name=="kf-cli")|.version) // "n/a"' "$ROOT_MARKET" 2>/dev/null; }

# ── version consistency across ALL FIVE canonical locations ──────────────────
check_versions() {
  local v_plugin v_market v_skill v_chg v_root fail=0
  v_plugin=$(jq -r '.version' "$KF/.claude-plugin/plugin.json" 2>/dev/null)
  v_market=$(jq -r '.metadata.version' "$KF/.claude-plugin/marketplace.json" 2>/dev/null)
  v_skill=$(grep -m1 'version:' "$KF/SKILL.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  v_chg=$(grep -m1 -oE '\[[0-9]+\.[0-9]+\.[0-9]+\]' "$KF/CHANGELOG.md" | tr -d '[]')
  v_root=$(root_kf_version)
  echo "  plugin.json           : $v_plugin"
  echo "  plugin marketplace.json: $v_market"
  echo "  SKILL.md              : $v_skill"
  echo "  CHANGELOG (top)       : $v_chg"
  echo "  ROOT marketplace.json : $v_root"
  if [[ "$v_plugin" == "$v_market" && "$v_plugin" == "$v_skill" \
        && "$v_plugin" == "$v_chg" && "$v_plugin" == "$v_root" ]]; then
    green "  ✓ versions consistent ($v_plugin)"
  else
    red   "  ✗ VERSION DRIFT — all FIVE must match (root manifest is the one that silently drifts)"; fail=1
  fi
  return $fail
}

# ── JSON validity ────────────────────────────────────────────────────────────
check_json() {
  local fail=0
  for f in "$KF/.claude-plugin/plugin.json" "$KF/.claude-plugin/marketplace.json" "$ROOT_MARKET"; do
    if jq -e . "$f" >/dev/null 2>&1; then green "  ✓ valid JSON: ${f#$REPO_ROOT/}"
    else red "  ✗ invalid JSON: ${f#$REPO_ROOT/}"; fail=1; fi
  done
  return $fail
}

# ── SKILL.md frontmatter must parse under STRICT YAML ────────────────────────
# The `skills` CLI (npx skills add/update) uses a strict YAML parser. An unquoted
# scalar containing a colon-space (e.g. "Commands: /capture") throws and the skill
# silently becomes uninstallable. Require quoting on scalar frontmatter values.
check_skillmd() {
  local fail=0
  # Try a real strict parse if python+yaml is available (authoritative).
  if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
    if python3 - "$KF/SKILL.md" <<'PY'
import sys, yaml
t = open(sys.argv[1]).read()
if t.startswith('---'):
    fm = t.split('---', 2)[1]
    yaml.safe_load(fm)
PY
    then green "  ✓ SKILL.md frontmatter parses (strict YAML)"
    else red "  ✗ SKILL.md frontmatter FAILS strict YAML — quote the offending value (e.g. description:)"; fail=1
    fi
  else
    # Heuristic fallback: description must be quoted (the known failure mode).
    if grep -qE '^description:[[:space:]]*["'\'']' "$KF/SKILL.md"; then
      green "  ✓ SKILL.md description is quoted"
    else
      red "  ✗ SKILL.md 'description:' is unquoted — quote it (breaks the strict YAML parser in npx skills)"; fail=1
    fi
  fi
  return $fail
}

# ── identity-free audit (scoped to plugins/kf-cli only) ──────────────────────
check_audit() {
  local fail=0 hits
  hits=$(grep -rInE "claude-(sonnet|opus|haiku)|gpt-[0-9]|gemini-[0-9]|glm-|ollama/|minimax" \
           "$KF" --include='*.md' --include='*.json' --include='*.sh' 2>/dev/null \
         | grep -v 'grep -' || true)
  if [[ -n "$hits" ]]; then red "  ✗ model-name leak:"; echo "$hits" | sed 's/^/      /'; fail=1
  else green "  ✓ no model names"; fi
  hits=$(grep -rInE '\b(Kira|Zorro)\b' "$KF" --include='*.md' --include='*.json' --include='*.sh' 2>/dev/null || true)
  if [[ -n "$hits" ]]; then red "  ✗ identity leak:"; echo "$hits" | sed 's/^/      /'; fail=1
  else green "  ✓ no identity leak"; fi
  hits=$(grep -rInF 'Documents/Obsidian' "$KF" --include='*.md' --include='*.sh' 2>/dev/null \
         | grep -v 'KF_VAULT_PATH' || true)
  if [[ -n "$hits" ]]; then
    yellow "  ⚠ vault-path mentions not paired with KF_VAULT_PATH (review — OK in docs/fallback prose):"
    echo "$hits" | sed 's/^/      /'
  else green "  ✓ no stray vault paths"; fi
  return $fail
}

cmd_check() {
  local rc=0
  echo "▸ Version consistency (5 spots)";              check_versions || rc=1
  echo "▸ JSON validity";                              check_json     || rc=1
  echo "▸ SKILL.md strict-YAML frontmatter";           check_skillmd  || rc=1
  echo "▸ Identity-free audit (plugins/kf-cli)";       check_audit    || rc=1
  echo
  if [[ $rc -eq 0 ]]; then green "PASS — canonical repo is release-ready"; else red "FAIL — fix the ✗ items above"; fi
  return $rc
}

# ── mirror: reuse an existing clone or clone on demand (portable) ────────────
_MIRROR_TMP=""
cleanup_mirror() { [[ -n "$_MIRROR_TMP" && -d "$_MIRROR_TMP" ]] && rm -rf "$_MIRROR_TMP"; _MIRROR_TMP=""; }
trap cleanup_mirror EXIT

resolve_mirror() {
  # 1) explicit env, 2) legacy default clone, 3) clone on demand → echoes the path
  local d
  for d in "${KF_STANDALONE_DIR:-}" "$HOME/Dev/zorcorp/kf-cli-sync"; do
    if [[ -n "$d" && -d "$d/.git" ]]; then echo "$d"; return 0; fi
  done
  _MIRROR_TMP="$(mktemp -d -t kf-mirror.XXXXXX)"
  if git clone --quiet "$MIRROR_URL" "$_MIRROR_TMP" 2>/dev/null; then
    echo "$_MIRROR_TMP"; return 0
  fi
  red "could not find or clone the mirror ($MIRROR_URL)" >&2; return 1
}

cmd_status() {
  echo "CANONICAL  (zorskill/plugins/kf-cli):"
  check_versions || true
  echo
  local mirror; mirror=$(resolve_mirror) || return 1
  echo "MIRROR     (ZorCorp/kf-cli @ $mirror):"
  echo "  marketplace.json : $(jq -r '.metadata.version // "n/a"' "$mirror/.claude-plugin/marketplace.json" 2>/dev/null)"
  echo "  SKILL.md         : $(grep -m1 'version:' "$mirror/SKILL.md" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
  local cv; cv=$(canon_version)
  if grep -q "version: \"$cv\"" "$mirror/SKILL.md" 2>/dev/null; then green "  ✓ mirror matches canonical ($cv)"
  else yellow "  ⚠ mirror is BEHIND canonical ($cv) — run: $0 sync (or release)"; fi
}

# ── bump the 5 version spots + prepend a CHANGELOG entry (no git) ─────────────
bump_versions() {
  local ver="$1" note="${2:-release}" today tmp
  [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { red "version must be x.y.z"; return 2; }
  today="$(date +%Y-%m-%d)"
  # 1. plugin.json
  tmp=$(mktemp); jq --arg v "$ver" '.version=$v' "$KF/.claude-plugin/plugin.json" >"$tmp" && mv "$tmp" "$KF/.claude-plugin/plugin.json"
  # 2. plugin marketplace.json (metadata + any plugins[])
  tmp=$(mktemp); jq --arg v "$ver" '.metadata.version=$v | (if .plugins then .plugins|=map(.version=$v) else . end)' \
      "$KF/.claude-plugin/marketplace.json" >"$tmp" && mv "$tmp" "$KF/.claude-plugin/marketplace.json"
  # 3. ROOT marketplace.json (kf-cli entry only)
  tmp=$(mktemp); jq --arg v "$ver" '(.plugins[]|select(.name=="kf-cli")|.version)=$v' "$ROOT_MARKET" >"$tmp" && mv "$tmp" "$ROOT_MARKET"
  # 4. SKILL.md frontmatter metadata.version
  sed -i '' -E 's/^([[:space:]]*version:[[:space:]]*")[0-9]+\.[0-9]+\.[0-9]+(")/\1'"$ver"'\2/' "$KF/SKILL.md"
  # 5. CHANGELOG — prepend a new entry above the first existing "## ["
  tmp=$(mktemp)
  awk -v ver="$ver" -v day="$today" -v note="$note" '
    !done && /^## \[/ { print "## [" ver "] - " day "\n\n- " note "\n"; done=1 }
    { print }
    END { if (!done) print "\n## [" ver "] - " day "\n\n- " note "\n" }
  ' "$KF/CHANGELOG.md" >"$tmp" && mv "$tmp" "$KF/CHANGELOG.md"
  green "  ✓ bumped all 5 spots + CHANGELOG → $ver"
}

# ── copy shared content canonical → a given mirror dir + bump its manifest ────
sync_to() {
  local dst="$1" cv; cv=$(canon_version)
  for item in SKILL.md README.md COMMANDS.md CHANGELOG.md TROUBLESHOOTING.md MIGRATION.md \
              commands templates scripts hooks; do
    [[ -e "$KF/$item" ]] || continue
    if [[ -d "$KF/$item" ]]; then rsync -a --delete "$KF/$item/" "$dst/$item/"
    else rsync -a "$KF/$item" "$dst/$item"; fi
  done
  # install.sh is MIRROR-OWNED — never overwrite it from canonical.
  if [[ -f "$dst/.claude-plugin/marketplace.json" ]]; then
    local tmp; tmp=$(mktemp)
    jq --arg v "$cv" '.metadata.version=$v | (if .plugins then .plugins|=map(.version=$v) else . end)' \
       "$dst/.claude-plugin/marketplace.json" >"$tmp" && mv "$tmp" "$dst/.claude-plugin/marketplace.json"
  fi
  green "  ✓ synced shared content → mirror ($cv)"
}

cmd_sync() {
  cmd_check || { red "Refusing to sync — canonical failed 'check'. Fix it first."; exit 1; }
  local mirror; mirror=$(resolve_mirror) || exit 1
  echo "▸ Syncing → $mirror"
  sync_to "$mirror"
  green "Sync staged. Review & push:  git -C $mirror status && git -C $mirror add -A && git -C $mirror commit -m 'sync' && git -C $mirror push"
}

# ── downstream refresh: bring local agent installs to the just-released version ─
refresh_agents() {
  local mirror="$1"
  if [[ -f "$mirror/install.sh" ]]; then
    echo "▸ Refreshing ~/.agents/skills/kf-cli via install.sh --update"
    bash "$mirror/install.sh" --update || yellow "  ⚠ agent refresh failed — run it manually"
    # Claude Code consumes kf-cli via the zorskill marketplace PLUGIN, not a skill.
    # install.sh auto-links every detected tool, so it recreates a duplicate
    # ~/.claude/skills/kf-cli symlink that shadows the plugin — drop it (symlink only).
    if [[ -L "$HOME/.claude/skills/kf-cli" ]]; then
      rm -f "$HOME/.claude/skills/kf-cli"
      echo "  ✓ removed duplicate ~/.claude/skills/kf-cli symlink (Claude Code uses the plugin)"
    fi
  else
    yellow "  ⚠ mirror install.sh not found; refresh agents manually"
  fi
  echo "▸ Claude Code: run  /reload-plugins  in your session to pick up the new plugin version."
}

cmd_release() {
  local ver="$1" note="${2:-release}" push=1 refresh=1
  shift 2 || true
  for a in "$@"; do case "$a" in --no-push) push=0;; --no-refresh) refresh=0;; esac; done
  [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { red "usage: $0 release <x.y.z> \"note\" [--no-push] [--no-refresh]"; exit 2; }

  echo "▸ 1/5 bump versions → $ver";      bump_versions "$ver" "$note" || exit 1
  echo "▸ 2/5 check";                     cmd_check || { red "check failed — aborting (files were bumped; revert or fix)"; exit 1; }
  echo "▸ 3/5 commit canonical"
  git -C "$REPO_ROOT" add "plugins/kf-cli" ".claude-plugin/marketplace.json"
  git -C "$REPO_ROOT" commit -q -m "kf-cli v$ver: $note" || yellow "  (nothing to commit?)"
  local mirror; mirror=$(resolve_mirror) || exit 1
  echo "▸ 4/5 sync mirror ($mirror)";     sync_to "$mirror"
  if [[ $push -eq 1 ]]; then
    git -C "$REPO_ROOT" push origin main
    git -C "$mirror" add -A && git -C "$mirror" commit -q -m "sync from zorskill v$ver" && git -C "$mirror" push
    green "  ✓ pushed canonical (main) + mirror"
  else
    yellow "  --no-push: canonical committed locally; mirror synced but NOT pushed. Push manually when ready."
  fi
  echo "▸ 5/5 downstream refresh"
  [[ $refresh -eq 1 ]] && refresh_agents "$mirror" || echo "  (skipped --no-refresh)"
  echo
  green "Release $ver done."
}

case "${1:-check}" in
  check)    cmd_check ;;
  status|versions) cmd_status ;;
  bump)     shift; bump_versions "$@" ;;
  sync)     cmd_sync ;;
  release)  shift; cmd_release "$@" ;;
  *) echo "usage: $0 {check|status|bump <x.y.z> \"note\"|sync|release <x.y.z> \"note\" [--no-push] [--no-refresh]}"; exit 2 ;;
esac

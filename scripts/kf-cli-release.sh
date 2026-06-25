#!/usr/bin/env bash
# kf-cli-release.sh — release guardrails + cross-repo sync for kf-cli.
#
# kf-cli is published from TWO repos that must stay in sync:
#   • CANONICAL: ZorCorp/zorskill  → plugins/kf-cli/   (Claude Code plugin marketplace)
#   • MIRROR:    ZorCorp/kf-cli     (standalone Agent Skill: npx skills / gh skill install)
# zorskill is the source of truth; the standalone repo is synced FROM it.
#
# Usage:
#   scripts/kf-cli-release.sh check       # within-canonical consistency + audit + JSON  (default)
#   scripts/kf-cli-release.sh versions    # show versions in BOTH repos side by side
#   scripts/kf-cli-release.sh sync        # copy shared content canonical → standalone, bump its version
#
# Env:
#   KF_STANDALONE_DIR   local clone of ZorCorp/kf-cli   (default: ~/Dev/zorcorp/kf-cli-sync)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KF="$REPO_ROOT/plugins/kf-cli"                                   # canonical
DST="${KF_STANDALONE_DIR:-$HOME/Dev/zorcorp/kf-cli-sync}"        # standalone mirror clone

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }

canon_version() { jq -r '.version' "$KF/.claude-plugin/plugin.json"; }

# ── version consistency WITHIN the canonical repo ────────────────────────────
check_versions() {
  local v_plugin v_market v_skill v_chg fail=0
  v_plugin=$(jq -r '.version' "$KF/.claude-plugin/plugin.json" 2>/dev/null)
  v_market=$(jq -r '.metadata.version' "$KF/.claude-plugin/marketplace.json" 2>/dev/null)
  v_skill=$(grep -m1 'version:' "$KF/SKILL.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  v_chg=$(grep -m1 -oE '\[[0-9]+\.[0-9]+\.[0-9]+\]' "$KF/CHANGELOG.md" | tr -d '[]')
  echo "  plugin.json      : $v_plugin"
  echo "  marketplace.json : $v_market"
  echo "  SKILL.md         : $v_skill"
  echo "  CHANGELOG (top)  : $v_chg"
  if [[ "$v_plugin" == "$v_market" && "$v_plugin" == "$v_skill" && "$v_plugin" == "$v_chg" ]]; then
    green "  ✓ versions consistent ($v_plugin)"
  else
    red   "  ✗ VERSION DRIFT — all four must match"; fail=1
  fi
  return $fail
}

# ── JSON validity ────────────────────────────────────────────────────────────
check_json() {
  local fail=0
  for f in "$KF/.claude-plugin/plugin.json" "$KF/.claude-plugin/marketplace.json"; do
    if jq -e . "$f" >/dev/null 2>&1; then green "  ✓ valid JSON: ${f#$KF/}"
    else red "  ✗ invalid JSON: ${f#$KF/}"; fail=1; fi
  done
  return $fail
}

# ── identity-free audit (scoped to plugins/kf-cli only) ──────────────────────
check_audit() {
  local fail=0 hits
  # model names (filter out the README's own audit-command lines, which contain the pattern literally)
  hits=$(grep -rInE "claude-(sonnet|opus|haiku)|gpt-[0-9]|gemini-[0-9]|glm-|ollama/|minimax" \
           "$KF" --include='*.md' --include='*.json' --include='*.sh' 2>/dev/null \
         | grep -v 'grep -' || true)
  if [[ -n "$hits" ]]; then red "  ✗ model-name leak:"; echo "$hits" | sed 's/^/      /'; fail=1
  else green "  ✓ no model names"; fi
  # identity leak
  hits=$(grep -rInE '\b(Kira|Zorro)\b' "$KF" --include='*.md' --include='*.json' --include='*.sh' 2>/dev/null || true)
  if [[ -n "$hits" ]]; then red "  ✗ identity leak:"; echo "$hits" | sed 's/^/      /'; fail=1
  else green "  ✓ no identity leak"; fi
  # hardcoded vault paths NOT paired with KF_VAULT_PATH (warning — docs legitimately mention the fallback)
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
  echo "▸ Version consistency (canonical)";        check_versions || rc=1
  echo "▸ JSON validity";                          check_json     || rc=1
  echo "▸ Identity-free audit (plugins/kf-cli)";   check_audit    || rc=1
  echo
  if [[ $rc -eq 0 ]]; then green "PASS — canonical repo is release-ready"; else red "FAIL — fix the ✗ items above"; fi
  return $rc
}

cmd_versions() {
  echo "CANONICAL  (zorskill/plugins/kf-cli):"
  check_versions || true
  echo
  echo "MIRROR     (ZorCorp/kf-cli @ $DST):"
  if [[ -d "$DST" ]]; then
    echo "  marketplace.json : $(jq -r '.metadata.version // "n/a"' "$DST/.claude-plugin/marketplace.json" 2>/dev/null)"
    echo "  SKILL.md         : $(grep -m1 'version:' "$DST/SKILL.md" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
    echo "  CHANGELOG (top)  : $(grep -m1 -oE '\[[0-9]+\.[0-9]+\.[0-9]+\]' "$DST/CHANGELOG.md" 2>/dev/null | tr -d '[]')"
    local cv; cv=$(canon_version)
    if grep -q "version: \"$cv\"" "$DST/SKILL.md" 2>/dev/null; then green "  ✓ mirror SKILL.md matches canonical ($cv)"
    else yellow "  ⚠ mirror is BEHIND canonical ($cv) — run: $0 sync"; fi
  else
    red "  ✗ standalone clone not found at $DST (set KF_STANDALONE_DIR)"
  fi
}

cmd_sync() {
  [[ -d "$DST" ]] || { red "standalone clone not found at $DST (set KF_STANDALONE_DIR)"; exit 1; }
  cmd_check || { red "Refusing to sync — canonical repo failed 'check'. Fix it first."; exit 1; }
  local cv; cv=$(canon_version)
  echo
  echo "▸ Syncing shared content → $DST (version $cv)"
  # Shared content (each repo keeps its own .claude-plugin/ and .git/).
  for item in SKILL.md README.md COMMANDS.md CHANGELOG.md TROUBLESHOOTING.md MIGRATION.md install.sh \
              commands templates scripts hooks; do
    [[ -e "$KF/$item" ]] || continue
    if [[ -d "$KF/$item" ]]; then
      rsync -a --delete "$KF/$item/" "$DST/$item/"
    else
      rsync -a "$KF/$item" "$DST/$item"
    fi
  done
  # Bump the mirror's own version file (marketplace.json — it is NOT part of synced content).
  if [[ -f "$DST/.claude-plugin/marketplace.json" ]]; then
    tmp=$(mktemp)
    jq --arg v "$cv" '.metadata.version=$v | (if .plugins then .plugins |= map(.version=$v) else . end)' \
       "$DST/.claude-plugin/marketplace.json" > "$tmp" && mv "$tmp" "$DST/.claude-plugin/marketplace.json"
    green "  ✓ bumped mirror marketplace.json → $cv"
  fi
  echo
  green "Sync staged. NOW REVIEW before pushing the mirror:"
  echo "  git -C $DST status"
  echo "  git -C $DST diff"
  echo "  # reconcile any standalone-specific README/install bits, then:"
  echo "  git -C $DST add -A && git -C $DST commit -m 'sync from zorskill v$cv' && git -C $DST push"
}

case "${1:-check}" in
  check)    cmd_check ;;
  versions) cmd_versions ;;
  sync)     cmd_sync ;;
  *) echo "usage: $0 {check|versions|sync}"; exit 2 ;;
esac

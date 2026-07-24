#!/usr/bin/env bash
# kf-cli-refresh-agents.sh — refresh NON-Claude agent installs of kf-cli.
#
# Why this exists:
#   kf-cli is now a submodule of ZorCorp/kf-cli, and the marketplace/aggregation
#   side is released with `zorskill-dev release kf-cli <ver>`. But zorskill-dev
#   deliberately NEVER touches a plugin's own repo OR agent installs. Non-Claude
#   agents (Hermes, etc.) consume the FULL kf-cli tree from ~/.agents/skills/kf-cli
#   (commands/ + templates/ + scripts/ — NOT just SKILL.md), installed via the
#   plugin's own install.sh. This is the one piece of the retired kf-cli-dev
#   (kf-cli-release.sh) worth keeping.
#
# Run this AFTER you have committed + pushed the kf-cli change to its own repo
# (ZorCorp/kf-cli, i.e. the plugins/kf-cli submodule), so the agent install picks
# up the new version.
#
# ⚠ Never use `npx skills` for kf-cli — it installs only SKILL.md and strips
#   commands/+templates/, breaking /watch. Always use install.sh.
set -euo pipefail

ZORSKILL="${ZORSKILL_DIR:-$HOME/Dev/zorcorp/zorskill}"
INSTALL="$ZORSKILL/plugins/kf-cli/install.sh"
[[ -f "$INSTALL" ]] || INSTALL="$(find "$HOME/Dev" -maxdepth 5 -path '*/kf-cli/install.sh' 2>/dev/null | head -1)"
[[ -f "$INSTALL" ]] || { echo "✗ kf-cli install.sh not found (looked under \$ZORSKILL and ~/Dev)" >&2; exit 1; }

echo "▸ Refreshing ~/.agents/skills/kf-cli via install.sh --update"
bash "$INSTALL" --update || { echo "  ⚠ agent refresh failed — run it manually: bash \"$INSTALL\" --update" >&2; exit 1; }

# Claude Code consumes kf-cli via the zorskill marketplace PLUGIN, not a skill.
# install.sh auto-links detected tools and may recreate a duplicate
# ~/.claude/skills/kf-cli symlink that shadows the plugin — drop it (symlink only).
if [[ -L "$HOME/.claude/skills/kf-cli" ]]; then
  rm -f "$HOME/.claude/skills/kf-cli"
  echo "  ✓ removed duplicate ~/.claude/skills/kf-cli symlink (Claude Code uses the plugin)"
fi

echo "✓ Agents refreshed (~/.agents/skills/kf-cli). Claude Code: run /reload-plugins for the plugin."

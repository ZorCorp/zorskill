#!/usr/bin/env bash
# install.sh — kf-cli installer for ~/.agents/skills/kf-cli/
#
# This installer targets the **agent-skill standard layout** used by OpenClaw
# and any framework that scans `~/.agents/skills/*/SKILL.md`. Claude Code
# users should use the plugin marketplace (see README).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ZorCorp/kf-cli/master/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --update
#   curl -fsSL .../install.sh | bash -s -- --uninstall
#
# Advanced: override the source tarball (e.g. to test a feature branch)
#   REPO_TARBALL=https://github.com/ZorCorp/kf-cli/archive/refs/heads/my-branch.tar.gz \
#     bash install.sh

set -euo pipefail

REPO_TARBALL="${REPO_TARBALL:-https://github.com/ZorCorp/kf-cli/archive/refs/heads/master.tar.gz}"
INSTALL_DIR="$HOME/.agents/skills/kf-cli"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$HOME/.agents/skills/kf-cli.bak-$TIMESTAMP"
STAGING=""

cleanup() {
    if [[ -n "$STAGING" && -d "$STAGING" ]]; then
        rm -rf "$STAGING"
    fi
}
trap cleanup EXIT

MODE="install"
for arg in "$@"; do
    case "$arg" in
        --update)     MODE="update" ;;
        --uninstall)  MODE="uninstall" ;;
        *) echo "Unknown arg: $arg" >&2; exit 2 ;;
    esac
done

uninstall() {
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        echo "✓ Removed $INSTALL_DIR"
    else
        echo "Nothing to uninstall at $INSTALL_DIR"
    fi
    # preserve the most recent .bak-* (do not touch backups)
}

fetch_and_extract() {
    local dest="$1"
    mkdir -p "$dest"
    if ! curl -fsSL "$REPO_TARBALL" | tar -xz --strip-components=1 -C "$dest"; then
        echo "❌ Failed to fetch or extract $REPO_TARBALL" >&2
        exit 1
    fi
    # Defensive: ensure bundled scripts are executable even if the tarball
    # didn't preserve the mode bits.
    if [[ -d "$dest/scripts" ]]; then
        find "$dest/scripts" -type f -name "*.sh" -exec chmod +x {} \;
    fi
}

check_deps() {
    local missing_required=0
    for tool in yt-dlp gh jq curl tar; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_required=1
            case "$tool" in
                yt-dlp) echo "⚠ yt-dlp not found — install: brew install yt-dlp" ;;
                gh)     echo "⚠ gh not found — install: brew install gh" ;;
                jq)     echo "⚠ jq not found — install: brew install jq" ;;
                curl)   echo "⚠ curl not found — install via your system package manager" ;;
                tar)    echo "⚠ tar not found — install via your system package manager" ;;
            esac
        fi
    done
    # uvx is optional — only YouTube transcript capture needs it
    if ! command -v uvx >/dev/null 2>&1; then
        echo "ℹ uvx not found (optional — required for YouTube transcripts): brew install uv"
    fi
    return $missing_required
}

prune_backups() {
    # Keep the most recent backup only
    local parent="$HOME/.agents/skills"
    local pattern="$parent/kf-cli.bak-"
    local -a olds
    # shellcheck disable=SC2207
    olds=($(ls -dt "$pattern"* 2>/dev/null | tail -n +2))
    if (( ${#olds[@]} > 0 )); then
        rm -rf "${olds[@]}"
    fi
}

print_next_steps() {
    cat <<'EOS'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Restart your agent so it picks up the new skill.
     • OpenClaw:    openclaw gateway restart
     • Claude Code: use the plugin marketplace instead (see README)

2. Authenticate gh once if you haven't (needed for /kf-cli:gitingest):
     gh auth login

3. Configure your vault + publishing target:
     cd /path/to/your/obsidian/vault
     export KF_VAULT_PATH="$PWD"
     # then from an agent turn:
     /kf-cli:setup

4. Verify the install:
     head -5 ~/.agents/skills/kf-cli/SKILL.md
     # should print "name: kf-cli" in the frontmatter

EOS
}

case "$MODE" in
    uninstall)
        uninstall
        exit 0
        ;;
    install|update)
        mkdir -p "$HOME/.agents/skills"
        if [[ -d "$INSTALL_DIR" ]]; then
            STAGING="$(mktemp -d)"
            fetch_and_extract "$STAGING"
            if diff -qr "$INSTALL_DIR" "$STAGING" >/dev/null 2>&1; then
                echo "✓ Already up-to-date at $INSTALL_DIR"
            else
                mv "$INSTALL_DIR" "$BACKUP_DIR"
                mv "$STAGING" "$INSTALL_DIR"
                STAGING=""   # mv consumed it — don't re-cleanup
                echo "✓ Installed to $INSTALL_DIR (previous version backed up to $BACKUP_DIR)"
                prune_backups
            fi
        else
            fetch_and_extract "$INSTALL_DIR"
            echo "✓ Installed to $INSTALL_DIR"
        fi
        # check_deps returns non-zero when required tools are missing. The `|| echo ...`
        # is load-bearing under `set -euo pipefail`: without it the script would abort
        # here instead of printing the next-steps block below. Do not "simplify" by
        # removing the `||` — the non-zero return is intentional and informational.
        check_deps || echo "   (install skills that need missing tools will fail until the warnings above are fixed)"
        print_next_steps
        ;;
esac

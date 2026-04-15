---
description: Standalone vault search using ripgrep + LLM rerank (no Obsidian required)
argument-hint: <query> [--top N] [--no-rerank]
allowed-tools:
  - Bash(rg:*)
  - Bash(grep:*)
  - Bash(test:*)
  - Bash(head:*)
  - Bash(sort:*)
  - Bash(command:*)
  - Bash(printf:*)
  - Bash(echo:*)
---

## Context

- **Query:** `$ARGUMENTS`
- **Retrieval:** ripgrep (fallback: grep) over `$VAULT_PATH/notes/*.md`
- **Rerank:** LLM semantic rerank of the top-N candidates (unless `--no-rerank`)

No Obsidian, no Local REST API, no network. Runs entirely on local files.

## Task

Perform a two-tier search of the vault's `notes/` directory:

1. **Tier 1 — Text retrieval** via ripgrep: find the top-N notes that contain the query terms, ranked by match count.
2. **Tier 2 — LLM rerank:** read excerpts from those candidates and reorder them by semantic relevance to the query, with a one-line justification per result.

## Implementation

### Step 1 — Parse arguments and resolve vault path

```bash
# Parse: first positional is the query; flags: --top N, --no-rerank
RAW_ARGS="$ARGUMENTS"
TOP_N=10
RERANK=1
QUERY=""

# Very small arg parser — tolerate flags in any order
set -- $RAW_ARGS
while [[ $# -gt 0 ]]; do
    case "$1" in
        --top)
            TOP_N="$2"; shift 2 ;;
        --no-rerank)
            RERANK=0; shift ;;
        *)
            if [[ -z "$QUERY" ]]; then
                QUERY="$1"
            else
                QUERY="$QUERY $1"
            fi
            shift ;;
    esac
done

if [[ -z "$QUERY" ]]; then
    echo "❌ No search query provided"
    echo "   Usage: /kf-cli:semantic-search <query> [--top N] [--no-rerank]"
    exit 1
fi

# Resolve vault path: $KF_VAULT_PATH → cwd (if it has notes/) → ~/Documents/Obsidian/myrag
if [[ -n "$KF_VAULT_PATH" && -d "$KF_VAULT_PATH/notes" ]]; then
    VAULT_PATH="$KF_VAULT_PATH"
elif [[ -d "$(pwd)/notes" ]]; then
    VAULT_PATH="$(pwd)"
elif [[ -d "$HOME/Documents/Obsidian/myrag/notes" ]]; then
    VAULT_PATH="$HOME/Documents/Obsidian/myrag"
else
    echo "❌ Could not resolve a vault path containing a notes/ directory."
    echo "   Set \$KF_VAULT_PATH, cd into a vault, or create ~/Documents/Obsidian/myrag/notes/"
    exit 1
fi

echo "🔍 Searching for: $QUERY"
echo "📁 Vault: $VAULT_PATH"
echo "🎯 Top-N: $TOP_N  |  Rerank: $([ $RERANK -eq 1 ] && echo on || echo off)"
echo ""
```

### Step 2 — Tier 1: ripgrep (with grep fallback)

```bash
# Prefer ripgrep; fall back to grep if unavailable
if command -v rg >/dev/null 2>&1; then
    CANDIDATES=$(rg --ignore-case --type md --count "$QUERY" "$VAULT_PATH/notes/" \
        | sort -t: -k2 -nr \
        | head -n "$TOP_N")
else
    echo "⚠️  ripgrep (rg) not found — falling back to grep"
    # grep -c emits "path:count"; filter zero-matches and sort like the rg path
    CANDIDATES=$(grep -rcI --include='*.md' -i "$QUERY" "$VAULT_PATH/notes/" \
        | grep -v ':0$' \
        | sort -t: -k2 -nr \
        | head -n "$TOP_N")
fi

if [[ -z "$CANDIDATES" ]]; then
    echo "No matches found for '$QUERY' in $VAULT_PATH/notes/"
    exit 0
fi

echo "### Tier 1 — Text matches (by count)"
echo ""
echo "$CANDIDATES"
echo ""
```

### Step 3 — Collect excerpts for rerank

```bash
if [[ $RERANK -eq 1 ]]; then
    echo "### Tier 1 — Excerpt context (±2 lines)"
    echo ""
    if command -v rg >/dev/null 2>&1; then
        rg --type md -C 2 --ignore-case "$QUERY" "$VAULT_PATH/notes/" | head -n 50
    else
        grep -rn -C 2 --include='*.md' -i "$QUERY" "$VAULT_PATH/notes/" | head -n 50
    fi
    echo ""
fi
```

### Step 4 — Tier 2: LLM rerank

If `$RERANK` is 1 (the default), the bash portion above has already printed the candidate list and excerpts to your context. **You (the LLM) must now perform the rerank directly** — do not shell out to another model.

Produce the final answer in this exact format:

```
### Tier 2 — Semantic rerank

1. [[notes/<filename>|<Title>]] — <one-line justification tying excerpt to query>
2. [[notes/<filename>|<Title>]] — <one-line justification>
...
```

Rules for the rerank:

- Use only the candidate files listed in Tier 1. Do not invent filenames.
- Judge each candidate by how well its *excerpts* address the query's intent, not just keyword frequency.
- If a candidate is clearly off-topic (e.g. keyword appears in boilerplate), demote or drop it and say why.
- Produce at most `$TOP_N` lines. Fewer is fine if several candidates are weak.
- Use Obsidian wikilink syntax so the user can click straight through.

If `--no-rerank` was passed, stop after Tier 1 — do not add commentary.

## Prerequisites

- `rg` (ripgrep) on PATH — **recommended**. Install via `brew install ripgrep`.
- `grep` — universally available, used as automatic fallback.
- A vault directory with a `notes/` subfolder.

## Examples

```bash
/kf-cli:semantic-search KnowledgeFactory migration
/kf-cli:semantic-search "claude code hooks" --top 5
/kf-cli:semantic-search obsidian --no-rerank
```

## Troubleshooting

- **"Could not resolve a vault path"** — `export KF_VAULT_PATH=/path/to/vault` or `cd` into the vault first.
- **"No matches found"** — try broader terms; ripgrep does literal (regex) matching, not semantic.
- **Slow on huge vaults** — lower `--top` or narrow the query.

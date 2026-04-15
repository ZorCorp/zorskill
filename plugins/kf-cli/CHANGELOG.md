# Changelog

All notable changes to kf-cli will be documented in this file.

## [0.4.6] - 2026-04-13

### Added
- `youtube-note` template: added `read: false` frontmatter field for Obsidian floating read-status button compatibility (📕/📖 toggle)

## [0.4.5] - 2026-04-13

### Fixed
- `article` command: GEMINI_API_KEY is env-var only — no app-specific fallback. If not set, image generation is skipped with a warning. Set via `export GEMINI_API_KEY="..."` in `~/.zshrc`.

## [0.4.4] - 2026-04-13

### Fixed
- Expanded `allowed-tools` in all 11 commands to eliminate Claude Code permission prompts
  - `article`: `Bash(date)` → `Bash(*)`
  - `capture`: `Bash(date)` → `Bash(*), Read(*), Write(*), WebFetch(*)`
  - `gitingest`: `WebFetch` → `WebFetch(*)`
  - `publish`: added `Bash(*), Read(*)` alongside `Task(*)`
  - `share`: added `Bash(*), Read(*)` alongside `Task(*)`
  - `study-guide`: `WebFetch` → `WebFetch(*)`
  - `youtube-note`: `WebFetch` → `WebFetch(*)`
  - `bulk-auto-tag`, `idea`, `semantic-search`, `setup`: already complete, no changes needed

## [0.4.3] - 2026-04-13

### Fixed
- `article` command: `{{TAGS}}` now uses canonical vault topic tags (claude-code, gemini, mcp, ai-tools, etc.) routed to correct wiki topics
- `article` template: tags now formatted as `[article, {{TAGS}}]` YAML inline array — prevents freeform tag format bugs
- `article` command: explicit rule added — tags must be in frontmatter only, never as `**Tags:** #foo` in body

## [0.1.0] - 2026-03-12

### Added
- Initial release of kf-cli — native CLI replacement for kf-claude
- All 11 commands ported from kf-claude with MCP → CLI tool replacement:
  - `/kf-cli:capture` — Smart content router
  - `/kf-cli:youtube-note` — YouTube video notes (yt-dlp + uvx transcript)
  - `/kf-cli:idea` — Quick idea capture
  - `/kf-cli:gitingest` — GitHub repository analysis (gh CLI)
  - `/kf-cli:study-guide` — Study guide generation (WebFetch)
  - `/kf-cli:article` — Article creation with Gemini hero images
  - `/kf-cli:publish` — GitHub Pages publishing
  - `/kf-cli:share` — URL-encoded sharing (zlib + base64 + CRC32)
  - `/kf-cli:bulk-auto-tag` — Bulk AI tagging
  - `/kf-cli:semantic-search` — Vault search via Obsidian REST API
  - `/kf-cli:setup` — Setup wizard with dependency checks
- SKILL.md with full CLI-native skill definition
- Templates symlinked from kf-claude (shared)
- Core scripts symlinked from kf-claude (publish.sh, fetch-youtube-transcript.sh, verify-publish.sh)
- Helper utilities in scripts/helpers/common.sh

### Changed (vs kf-claude)
- `mcp__MCP_DOCKER__obsidian_*` → `Write(*)` / `Read(*)` / `Edit(*)`
- `mcp__MCP_DOCKER__get_video_info` → `yt-dlp --dump-json`
- `mcp__MCP_DOCKER__get_transcript` → `scripts/core/fetch-youtube-transcript.sh`
- `mcp__MCP_DOCKER__fetch` / `firecrawl_scrape` → `WebFetch`
- MCP GitHub tools → `gh api`
- No Docker dependency required

### Performance
- Local I/O operations 100-500x faster (sub-ms vs MCP Docker overhead)
- No Docker cold start penalty (saves 2-5s on first call)
- Network-bound operations (yt-dlp, gh API) have similar latency

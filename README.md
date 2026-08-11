# zorskill

ZorCorp's AI skill collection — works with **Claude Code**, **OpenClaw**, **OpenCode**, **Antigravity CLI**, and any agent that follows the `~/.agents/skills/` convention.

## Skills

<!-- BEGIN SKILLS (managed by zorskill-dev) -->
| Skill | Description | Source |
|-------|-------------|--------|
| `kf-cli` | AI knowledge pipeline for Obsidian — capture any video URL, article, GitHub repo, or idea into auto-tagged notes, index them into a searchable wiki, and publish to GitHub Pages. CLI-native (no Docker or MCP). | [ZorCorp/kf-cli](https://github.com/ZorCorp/kf-cli) |
| `cx-trip-pa` | Search and book flights on Trip.com through a real browser (agent-browser), driven by the `/flight` command. | [ZorCorp/cx-trip-pa](https://github.com/ZorCorp/cx-trip-pa) |
| `code-to-video` | Turn existing web source code into a shareable demo video — analyzes the code, generates Stitch UI screens, renders a Remotion MP4, and uploads it to Google Drive. | [ZorCorp/code-to-video](https://github.com/ZorCorp/code-to-video) |
| `prototyper` | Convert a product's source code or Stitch UI designs into a standalone interactive HTML demo with auto-play, a simulated cursor, and animations. | [ZorCorp/prototyper](https://github.com/ZorCorp/prototyper) |
| `hermes-on-cf` | Deploy your own Hermes Agent — a stateful AI agent reachable from your own Telegram bot — to your own Cloudflare account (Worker + Container + R2 + AI Gateway). Self-service. | [ZorCorp/hermes-on-cf](https://github.com/ZorCorp/hermes-on-cf) |
| `openclaw-on-cf` | Deploy your own OpenClaw bot — an AI agent with a Telegram channel and a web dashboard — to your own Cloudflare account (Worker + Container + R2 + AI Gateway). Self-service. | [ZorCorp/openclaw-on-cf](https://github.com/ZorCorp/openclaw-on-cf) |
| `yellow-restaurant` | Find nearby yellow restaurants (黃店食肆) from the Yellow-Blue Map API using your GPS coordinates. | [ZorCorp/yellow-restaurant](https://github.com/ZorCorp/yellow-restaurant) |
| `zorskill-dev` | Maintainer tooling for this marketplace — audit version drift, release a plugin (advance its submodule pointer + sync the marketplace and this README), and scaffold new plugins. | [ZorCorp/zorskill-dev](https://github.com/ZorCorp/zorskill-dev) |
| `fc-bms2` | Query the Finda Cloud (FC) BMS operational database — orders, invoices, AR, gross profit, purchase orders, vendors, customers, products, exchange rates, sales attribution and the org chart — from its read-only BigQuery mirror behind a private Cloud Run endpoint. | [ZorCorp/fc-bms2](https://github.com/ZorCorp/fc-bms2) |
| `gcp-bq` | 🔒 Private (ZorCorp members only) — Query GCP cloud cost — price and cost by billing account, project, service, or SKU, for one month or a range. | [ZorCorp/gcp-bq](https://github.com/ZorCorp/gcp-bq) |
| `bms2` | Query the Master Concept BMS operational database (orders, invoices, gross profit, POs, vendors, suppliers, products, billing cost, exchange rates, org chart) from its read-only BigQuery mirror. | [ZorCorp/bms2](https://github.com/ZorCorp/bms2) |
| `mcai-webapp` | TODO one-line description of mcai-webapp | [ZorCorp/mcai-webapp](https://github.com/ZorCorp/mcai-webapp) |
<!-- END SKILLS -->

---

## Install

**Claude Code** users: use **Option C** (the plugin marketplace) — one command adds the whole collection and you get auto-update notifications. **Every other agent** (Codex, Cursor, Copilot, OpenClaw, OpenCode, Antigravity CLI, or anything that reads `~/.agents/skills/`): use **Option A** (`npx skills`, per-skill), **Option B** (`gh skill`), or **Option D** (npm, all skills at once). Options A/B/D install to the shared `~/.agents/skills/` location and symlink into each detected agent.

### Option A — `npx skills add` (recommended)

Installs any individual skill to `~/.agents/skills/` and auto-symlinks into every detected AI tool on your machine (Claude Code, Codex, Antigravity CLI, Cursor, Copilot).

```bash
npx skills add ZorCorp/kf-cli
npx skills add ZorCorp/prototyper
# repeat for each skill
```

Update / uninstall:

```bash
npx skills update ZorCorp/kf-cli
npx skills remove ZorCorp/kf-cli
```

Tell any AI agent to install a skill:

> Install the Agent Skill at github.com/ZorCorp/kf-cli using `npx skills add ZorCorp/kf-cli`.

### Option B — `gh skill install` (GitHub CLI)

Copy mode — interactive prompts for target agent and scope. Requires GitHub CLI 2.90.0+.

```bash
gh skill install ZorCorp/kf-cli
gh skill install ZorCorp/prototyper
```

### Option C — Claude Code (Plugin Marketplace)

Best for Claude Code users — auto-update notifications included.

```
/plugin marketplace add ZorCorp/zorskill
/plugin install kf-cli
/plugin install cx-trip-pa
/plugin install code-to-video
/plugin install prototyper
/plugin install hermes-on-cf
/plugin install openclaw-on-cf
/plugin install yellow-restaurant
/plugin install gcp-bq
/plugin install zorskill-dev
```

Update:

```
/plugin update zorskill
```

### Option D — npm (All Agents)

Installs all skills to `~/.agents/skills/` and auto-symlinks into every agent detected on your machine (Claude Code, OpenClaw, OpenCode, Antigravity CLI).

**Install all skills:**

```bash
npm install -g @zorcorp/zorskills
```

Update all skills:

```bash
npm update -g @zorcorp/zorskills
```

---

**Which should I pick?**

| Situation | Pick |
|---|---|
| Install individual skills, cross-tool (**recommended**) | **Option A** (`npx skills`) |
| Already using the `gh` CLI | Option B (`gh skill`) |
| Claude Code only, with auto-updates | Option C (marketplace) |
| Want all ZorCorp skills in one go | Option D (npm) |

### OpenClaw Install

OpenClaw picks up skills from `~/.openclaw/skills/`. Use Option A (`npx skills add`) or Option D (npm) for the easiest setup.

**Manual install (git + script — works without npm):**

```bash
git clone --recurse-submodules https://github.com/ZorCorp/zorskill.git /tmp/zorskill
cd /tmp/zorskill
node scripts/setup.js
```

Restart OpenClaw after install — skills are loaded on agent startup.

**Verify:**

```bash
ls ~/.openclaw/skills/
# kf-cli   cx-trip-pa   code-to-video   prototyper   hermes-on-cf   openclaw-on-cf   yellow-restaurant   gcp-bq   zorskill-dev
```

**Tested commands:**

| Command | Status |
|---------|--------|
| `/kf-cli:capture` | ✅ |
| `/kf-cli:idea` | ✅ |
| `/kf-cli:youtube-note` | ✅ |

---

## How It Works

```
npm install -g @zorcorp/zorskills
         │
         └─ scripts/setup.js runs automatically
                  │
                  ├─ ~/.agents/skills/kf-cli               ← canonical location
                  ├─ ~/.agents/skills/cx-trip-pa
                  ├─ ~/.agents/skills/code-to-video
                  ├─ ~/.agents/skills/prototyper
                  ├─ ~/.agents/skills/hermes-on-cf
                  ├─ ~/.agents/skills/openclaw-on-cf
                  ├─ ~/.agents/skills/yellow-restaurant
                  ├─ ~/.agents/skills/gcp-bq
                  ├─ ~/.agents/skills/zorskill-dev
                  │
                  ├─ ~/.claude/skills/kf-cli               → ../../.agents/skills/kf-cli
                  ├─ ~/.claude/skills/cx-trip-pa           → ../../.agents/skills/cx-trip-pa
                  ├─ ~/.claude/skills/code-to-video        → ../../.agents/skills/code-to-video
                  ├─ ~/.claude/skills/prototyper           → ../../.agents/skills/prototyper
                  ├─ ~/.claude/skills/hermes-on-cf         → ../../.agents/skills/hermes-on-cf
                  ├─ ~/.claude/skills/openclaw-on-cf       → ../../.agents/skills/openclaw-on-cf
                  ├─ ~/.claude/skills/yellow-restaurant    → ../../.agents/skills/yellow-restaurant
                  ├─ ~/.claude/skills/gcp-bq               → ../../.agents/skills/gcp-bq
                  └─ ~/.claude/skills/zorskill-dev         → ../../.agents/skills/zorskill-dev
                  │
                  ├─ ~/.openclaw/skills/kf-cli               → ../../.agents/skills/kf-cli
                  ├─ ~/.openclaw/skills/cx-trip-pa           → ../../.agents/skills/cx-trip-pa
                  ├─ ~/.openclaw/skills/code-to-video        → ../../.agents/skills/code-to-video
                  ├─ ~/.openclaw/skills/prototyper           → ../../.agents/skills/prototyper
                  ├─ ~/.openclaw/skills/hermes-on-cf         → ../../.agents/skills/hermes-on-cf
                  ├─ ~/.openclaw/skills/openclaw-on-cf       → ../../.agents/skills/openclaw-on-cf
                  ├─ ~/.openclaw/skills/yellow-restaurant    → ../../.agents/skills/yellow-restaurant
                  ├─ ~/.openclaw/skills/gcp-bq               → ../../.agents/skills/gcp-bq
                  └─ ~/.openclaw/skills/zorskill-dev         → ../../.agents/skills/zorskill-dev
                  │
                  ├─ ~/.opencode/skills/kf-cli               → ../../.agents/skills/kf-cli
                  ├─ ~/.opencode/skills/cx-trip-pa           → ../../.agents/skills/cx-trip-pa
                  ├─ ~/.opencode/skills/code-to-video        → ../../.agents/skills/code-to-video
                  ├─ ~/.opencode/skills/prototyper           → ../../.agents/skills/prototyper
                  ├─ ~/.opencode/skills/hermes-on-cf         → ../../.agents/skills/hermes-on-cf
                  ├─ ~/.opencode/skills/openclaw-on-cf       → ../../.agents/skills/openclaw-on-cf
                  ├─ ~/.opencode/skills/yellow-restaurant    → ../../.agents/skills/yellow-restaurant
                  ├─ ~/.opencode/skills/gcp-bq               → ../../.agents/skills/gcp-bq
                  └─ ~/.opencode/skills/zorskill-dev         → ../../.agents/skills/zorskill-dev
                  │
                  ├─ ~/.gemini/config/skills/kf-cli               → ../../.agents/skills/kf-cli
                  ├─ ~/.gemini/config/skills/cx-trip-pa           → ../../.agents/skills/cx-trip-pa
                  ├─ ~/.gemini/config/skills/code-to-video        → ../../.agents/skills/code-to-video
                  ├─ ~/.gemini/config/skills/prototyper           → ../../.agents/skills/prototyper
                  ├─ ~/.gemini/config/skills/hermes-on-cf         → ../../.agents/skills/hermes-on-cf
                  ├─ ~/.gemini/config/skills/openclaw-on-cf       → ../../.agents/skills/openclaw-on-cf
                  ├─ ~/.gemini/config/skills/yellow-restaurant    → ../../.agents/skills/yellow-restaurant
                  ├─ ~/.gemini/config/skills/gcp-bq               → ../../.agents/skills/gcp-bq
                  └─ ~/.gemini/config/skills/zorskill-dev         → ../../.agents/skills/zorskill-dev
```

`~/.agents/skills/` is the single source of truth. Each agent gets a symlink — no duplicated files, single update point.

---

## Adding a New Skill

> **For AI agents**: Read this entire section BEFORE writing any code or running any commands. Do not begin work until you have reviewed the full checklist below. Skipping steps is the most common failure mode — every step is required for the skill to be visible on the page.

### Required Completion Checklist

Before marking any task done, verify **all seven** of the following are complete:

- [ ] **Step 1** — Skill repo exists under `ZorCorp` org on GitHub
- [ ] **Step 2** — Skill added as submodule in the local vault (`zorcorp/zorskill/my-skill`)
- [ ] **Step 3** — Skill added as submodule in `ZorCorp/zorskill` (`plugins/my-skill`)
- [ ] **Step 4** — Entry added to `.claude-plugin/marketplace.json`
- [ ] **Step 5** — README updated in **all five** locations (Skills table, Option A install, OpenClaw verify, How It Works diagram, Structure diagram)
- [ ] **Step 6** — All changes committed and pushed to `ZorCorp/zorskill`
- [ ] **Step 7** — All four verification commands return matches

**The skill will NOT appear on the zorskill page until Steps 4 and 5 are done.** Adding the submodule alone (Steps 1–3) is necessary but not sufficient.

---

### Prerequisites

- `gh` CLI authenticated (`gh auth status`)
- Git configured with push access to `ZorCorp` org
- Local vault cloned at `~/Documents/Obsidian/Claudecode` (the Obsidian vault repo)
- A working clone of `ZorCorp/zorskill` (or use `/tmp/zorskill-update` if already cloned)

---

### Step 1 — Fork or create the skill repo under ZorCorp

**If the skill already exists as a public repo** (e.g. `CYH928/my-skill`):

```bash
gh api repos/CYH928/my-skill/forks -X POST -f organization=ZorCorp
```

Wait a few seconds, then verify:

```bash
gh api repos/ZorCorp/my-skill --jq '.full_name'
# Expected: ZorCorp/my-skill
```

**If you are creating a new skill from scratch**, create the repo under ZorCorp:

```bash
gh api orgs/ZorCorp/repos -X POST -f name=my-skill -f description="Short description" -f private=false
```

Then push your skill code to it.

---

### Step 2 — Add the skill as a submodule in the local vault

The vault (`~/Documents/Obsidian/Claudecode`) tracks all skill source repos as git submodules under `zorcorp/zorskill/`.

```bash
cd ~/Documents/Obsidian/Claudecode
git submodule add https://github.com/ZorCorp/my-skill.git zorcorp/zorskill/my-skill
```

Verify the submodule cloned:

```bash
ls zorcorp/zorskill/my-skill/
# Should show the skill's files (SKILL.md, commands/, etc.)
```

Commit the vault change:

```bash
git add .gitmodules zorcorp/zorskill/my-skill
git commit -m "chore: add my-skill as zorskill submodule

Co-Authored-By: Paperclip <noreply@paperclip.ing>"
```

---

### Step 3 — Add the skill as a submodule in ZorCorp/zorskill

Clone the zorskill marketplace repo if you don't have a local copy:

```bash
git clone https://github.com/ZorCorp/zorskill.git /tmp/zorskill-update
```

Or if already cloned, pull latest:

```bash
cd /tmp/zorskill-update && git pull origin main
```

Add the submodule:

```bash
cd /tmp/zorskill-update
git submodule add https://github.com/ZorCorp/my-skill.git plugins/my-skill
```

Verify:

```bash
ls plugins/my-skill/
cat .gitmodules | grep my-skill
```

---

### Step 4 — Register the skill in marketplace.json

Edit `.claude-plugin/marketplace.json` and add a new entry to the `plugins` array:

```json
{
  "name": "my-skill",
  "description": "One-line description of what the skill does.",
  "version": "1.0.0",
  "author": {
    "name": "AuthorName",
    "url": "https://github.com/AuthorName"
  },
  "source": "./plugins/my-skill",
  "category": "productivity"
}
```

Valid `category` values: `knowledge-management`, `productivity`.

---

### Step 5 — Update README.md (all sections)

Update **every** section of the README that lists skills. Do not add only one entry — check all locations:

| Section | What to update |
|---------|---------------|
| **Skills table** | Add a new row: skill name, description, link to `ZorCorp/my-skill` |
| **Option A install** | Add `/plugin install my-skill` |
| **OpenClaw verify** | Add `my-skill` to the `ls ~/.openclaw/skills/` comment |
| **How It Works diagram** | Add `~/.agents/skills/my-skill`, `~/.claude/skills/my-skill`, `~/.openclaw/skills/my-skill`, `~/.opencode/skills/my-skill`, `~/.gemini/config/skills/my-skill` |
| **Structure diagram** | Add `│   └── my-skill/  # submodule → ZorCorp/my-skill` |

---

### Step 6 — Commit and push ZorCorp/zorskill

```bash
cd /tmp/zorskill-update
git add .gitmodules plugins/my-skill .claude-plugin/marketplace.json README.md
git commit -m "feat: add my-skill

- Forked from <original-repo> (or: new skill)
- Added as git submodule at plugins/my-skill
- Registered in marketplace.json
- Updated README across all sections

Co-Authored-By: Paperclip <noreply@paperclip.ing>"

git push origin main
```

Verify on GitHub: `https://github.com/ZorCorp/zorskill` — confirm the new skill appears in the README Skills table and the `plugins/` folder.

---

### Step 7 — Verify the full setup

```bash
# 1. Vault submodule registered
cat ~/Documents/Obsidian/Claudecode/.gitmodules | grep my-skill

# 2. zorskill marketplace submodule registered
cat /tmp/zorskill-update/.gitmodules | grep my-skill

# 3. marketplace.json has the entry
cat /tmp/zorskill-update/.claude-plugin/marketplace.json | grep my-skill

# 4. README Skills table has the entry
grep my-skill /tmp/zorskill-update/README.md
```

All four checks should return matches.

---

### Skill file requirements

A valid zorskill plugin must have one of these layouts:

**Layout A — `commands/` style** (most skills):
```
my-skill/
├── SKILL.md          # name: frontmatter required
└── commands/
    └── my-skill.md   # one .md per slash command
```

**Layout B — `skills/` style** (e.g. sourcecode-to-video):
```
my-skill/
└── skills/
    └── my-skill/
        ├── SKILL.md
        └── sub-skills/
```

`SKILL.md` must include at minimum:
```yaml
---
name: my-skill
description: What the skill does.
---
```

---

## Structure

```
zorskill/
├── package.json                 # npm: @zorcorp/zorskills
├── scripts/
│   └── setup.js                 # post-install symlink creator
├── plugins/
│   ├── kf-cli/                 # submodule → ZorCorp/kf-cli
│   ├── cx-trip-pa/             # submodule → ZorCorp/cx-trip-pa
│   ├── code-to-video/          # submodule → ZorCorp/code-to-video
│   ├── prototyper/             # submodule → ZorCorp/prototyper
│   ├── hermes-on-cf/           # submodule → ZorCorp/hermes-on-cf
│   ├── openclaw-on-cf/         # submodule → ZorCorp/openclaw-on-cf
│   ├── yellow-restaurant/      # submodule → ZorCorp/yellow-restaurant
│   ├── gcp-bq/                 # submodule → ZorCorp/gcp-bq
│   └── zorskill-dev/           # submodule → ZorCorp/zorskill-dev (marketplace maintainer tooling)
└── README.md
```

---

**ZorCorp** · [github.com/ZorCorp](https://github.com/ZorCorp)

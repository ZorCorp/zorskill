# zorskill

ZorCorp's AI skill collection — works with **Claude Code**, **OpenClaw**, **OpenCode**, **Gemini CLI**, and any agent that follows the `~/.agents/skills/` convention.

## Skills

| Skill | Description | Source |
|-------|-------------|--------|
| `flight` | AI flight search via Trip.com (supports HK locale) | [ZorCorp/flight-skill](https://github.com/ZorCorp/flight-skill) |
| `kf-cli` | Obsidian knowledge management — capture, tag, publish | [ZorCorp/kf-cli](https://github.com/ZorCorp/kf-cli) |
| `kf-claude` | KnowledgeFactory (MCP/Docker version, legacy) | [ZorCorp/kf-claude](https://github.com/ZorCorp/kf-claude) |
| `sourcecode-to-video` | Turn web source code into a shareable demo video via Stitch + Remotion + Google Drive | [ZorCorp/sourcecode-to-video](https://github.com/ZorCorp/sourcecode-to-video) |
| `yellow-restaurant` | Find nearby yellow restaurants (黃店食肆) from the Yellow-Blue Map API | [ZorCorp/yellow-restaurant](https://github.com/ZorCorp/yellow-restaurant) |

---

## Install

### Option A — Claude Code (Plugin Marketplace)

Best for Claude Code users — auto-update notifications included.

```
/plugin marketplace add ZorCorp/zorskill
/plugin install kf-cli
/plugin install flight
/plugin install sourcecode-to-video
/plugin install yellow-restaurant
```

Update:

```
/plugin update zorskill
```

### Option B — npm (All Agents)

Installs all skills to `~/.agents/skills/` and auto-symlinks into every agent detected on your machine (Claude Code, OpenClaw, OpenCode, Gemini CLI).

```bash
npm install -g @zorcorp/zorskills
```

Only agents whose root directory exists on your machine are targeted — setup is safely skipped for agents you don't have installed.

Update all skills:

```bash
npm update -g @zorcorp/zorskills
```

### OpenClaw Install

OpenClaw picks up skills from `~/.openclaw/skills/`. Use Option B (npm) for the easiest setup.

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
# kf-cli   kf-claude   flight   sourcecode-to-video   yellow-restaurant
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
                  ├─ ~/.agents/skills/flight                  ← canonical location
                  ├─ ~/.agents/skills/kf-cli
                  ├─ ~/.agents/skills/sourcecode-to-video
                  ├─ ~/.agents/skills/yellow-restaurant
                  │
                  ├─ ~/.claude/skills/flight                  → ../../.agents/skills/flight
                  ├─ ~/.claude/skills/kf-cli                  → ../../.agents/skills/kf-cli
                  ├─ ~/.claude/skills/sourcecode-to-video     → ../../.agents/skills/sourcecode-to-video
                  ├─ ~/.claude/skills/yellow-restaurant       → ../../.agents/skills/yellow-restaurant
                  │
                  ├─ ~/.openclaw/skills/flight                → ../../.agents/skills/flight
                  ├─ ~/.openclaw/skills/kf-cli                → ../../.agents/skills/kf-cli
                  ├─ ~/.openclaw/skills/sourcecode-to-video   → ../../.agents/skills/sourcecode-to-video
                  ├─ ~/.openclaw/skills/yellow-restaurant     → ../../.agents/skills/yellow-restaurant
                  │
                  ├─ ~/.opencode/skills/flight                → ../../.agents/skills/flight
                  ├─ ~/.opencode/skills/kf-cli                → ../../.agents/skills/kf-cli
                  ├─ ~/.opencode/skills/sourcecode-to-video   → ../../.agents/skills/sourcecode-to-video
                  ├─ ~/.opencode/skills/yellow-restaurant     → ../../.agents/skills/yellow-restaurant
                  │
                  ├─ ~/.gemini/extensions/flight              → ../../.agents/skills/flight
                  ├─ ~/.gemini/extensions/kf-cli              → ../../.agents/skills/kf-cli
                  ├─ ~/.gemini/extensions/sourcecode-to-video → ../../.agents/skills/sourcecode-to-video
                  └─ ~/.gemini/extensions/yellow-restaurant   → ../../.agents/skills/yellow-restaurant
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
| **How It Works diagram** | Add `~/.agents/skills/my-skill`, `~/.claude/skills/my-skill`, `~/.openclaw/skills/my-skill`, `~/.opencode/skills/my-skill`, `~/.gemini/extensions/my-skill` |
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
│   ├── flight/                  # submodule → ZorCorp/flight-skill
│   ├── kf-cli/                  # submodule → ZorCorp/kf-cli
│   ├── kf-claude/               # submodule → ZorCorp/kf-claude (legacy)
│   ├── sourcecode-to-video/     # submodule → ZorCorp/sourcecode-to-video
│   └── yellow-restaurant/       # submodule → ZorCorp/yellow-restaurant
└── README.md
```

---

**ZorCorp** · [github.com/ZorCorp](https://github.com/ZorCorp)

# zorskill

ZorCorp's AI skill collection — works with **Claude Code**, **OpenClaw**, **OpenCode**, **Gemini CLI**, and any agent that follows the `~/.agents/skills/` convention.

## Skills

| Skill | Description | Source |
|-------|-------------|--------|
| `flight` | AI flight search via Trip.com (supports HK locale) | [ZorCorp/flight-skill](https://github.com/ZorCorp/flight-skill) |
| `kf-cli` | Obsidian knowledge management — capture, tag, publish | [ZorCorp/kf-cli](https://github.com/ZorCorp/kf-cli) |
| `kf-claude` | KnowledgeFactory (MCP/Docker version, legacy) | [ZorCorp/kf-claude](https://github.com/ZorCorp/kf-claude) |
| `sourcecode-to-video` | Turn web source code into a shareable demo video via Stitch + Remotion + Google Drive | [ZorCorp/sourcecode-to-video](https://github.com/ZorCorp/sourcecode-to-video) |

---

## Install

### Option A — Claude Code (Plugin Marketplace)

Best for Claude Code users — auto-update notifications included.

```
/plugin marketplace add ZorCorp/zorskill
/plugin install kf-cli
/plugin install flight
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
# kf-cli   kf-claude   flight
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
                  ├─ ~/.agents/skills/flight         ← canonical location
                  ├─ ~/.agents/skills/kf-cli
                  │
                  ├─ ~/.claude/skills/flight         → ../../.agents/skills/flight
                  ├─ ~/.claude/skills/kf-cli         → ../../.agents/skills/kf-cli
                  │
                  ├─ ~/.openclaw/skills/flight       → ../../.agents/skills/flight
                  ├─ ~/.openclaw/skills/kf-cli       → ../../.agents/skills/kf-cli
                  │
                  ├─ ~/.opencode/skills/flight       → ../../.agents/skills/flight
                  ├─ ~/.opencode/skills/kf-cli       → ../../.agents/skills/kf-cli
                  │
                  ├─ ~/.gemini/extensions/flight     → ../../.agents/skills/flight
                  └─ ~/.gemini/extensions/kf-cli     → ../../.agents/skills/kf-cli
```

`~/.agents/skills/` is the single source of truth. Each agent gets a symlink — no duplicated files, single update point.

---

## Adding a New Skill

Each skill is a git submodule under `plugins/`:

```bash
git submodule add https://github.com/ZorCorp/my-new-skill.git plugins/my-new-skill
git add .gitmodules plugins/my-new-skill
git commit -m "feat: add my-new-skill"
```

Skill requirements:
- `SKILL.md` with `name:` frontmatter
- `commands/` directory with one `.md` per command

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
│   └── sourcecode-to-video/     # submodule → ZorCorp/sourcecode-to-video
└── README.md
```

---

**ZorCorp** · [github.com/ZorCorp](https://github.com/ZorCorp)

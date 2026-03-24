# zorskill

ZorCorp's AI skill collection — works with **Claude Code**, **OpenClaw**, **OpenCode**, **Gemini CLI**, and any agent that follows the `~/.agents/skills/` convention.

## Skills

| Skill | Description | Source |
|-------|-------------|--------|
| `flight` | AI flight search via Trip.com (supports HK locale) | [ZorCorp/flight-skill](https://github.com/ZorCorp/flight-skill) |
| `kf-cli` | Obsidian knowledge management — capture, tag, publish | [ZorCorp/kf-cli](https://github.com/ZorCorp/kf-cli) |
| `kf-claude` | KnowledgeFactory (MCP/Docker version, legacy) | [ZorCorp/kf-claude](https://github.com/ZorCorp/kf-claude) |

---

## Install

### Option A — npm (recommended)

Installs all skills to `~/.agents/skills/` and auto-symlinks them into every agent it detects on your machine.

```bash
npm install -g @zorcorp/zorskills
```

Skills become available immediately in:
- **Claude Code** — invoke as `/skill-name`
- **OpenClaw** — agent picks up skills on next restart
- **OpenCode** — skills installed to `~/.opencode/skills/`
- **Gemini CLI** — extensions installed to `~/.gemini/extensions/`

Only agents whose root directory exists on your machine are targeted — setup is safely skipped for agents you don't have installed.

Update all skills at once:

```bash
npm update -g @zorcorp/zorskills
```

> **Note**: The npm package uses git submodules. Make sure they're checked out before publishing:
> `git submodule update --init --recursive`

### Option B — Claude Code Plugin Marketplace

Best for auto-update notifications inside Claude Code.

```
/plugin marketplace add ZorCorp/zorskill
/plugin install kf-cli
/plugin install flight
```

Update:

```
/plugin update zorskill
```

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
│   └── kf-claude/               # submodule → ZorCorp/kf-claude (legacy)
└── README.md
```

---

**ZorCorp** · [github.com/ZorCorp](https://github.com/ZorCorp)

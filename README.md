# zorskill

**AI-powered skill marketplace for Claude Code by ZorCorp**

zorskill consolidates ZorCorp's Claude Code plugins into a single installable marketplace.

## Plugins

| Plugin | Description | Source |
|--------|-------------|--------|
| `kf-claude` | KnowledgeFactory for Claude Code — Obsidian integration, AI capture, publishing (requires MCP/Docker) | [ZorroCheng-MC/kf-claude](https://github.com/ZorroCheng-MC/kf-claude) |
| `kf-cli` | KnowledgeFactory CLI — same commands as kf-claude, no Docker/MCP required | [ZorroCheng-MC/kf-cli](https://github.com/ZorroCheng-MC/kf-cli) |
| `flight` | AI flight search assistant via Trip.com | [laucw1213/flight-skill](https://github.com/laucw1213/flight-skill) |

## Installation

### Step 1: Add the zorskill marketplace

Inside Claude Code, run:

```
/plugin marketplace add ZorCorp/zorskill
```

This registers the zorskill marketplace and gives you access to all ZorCorp plugins.

### Step 2: Install a plugin

**Option A: Browse and install (recommended)**

```
/plugin
```

Opens an interactive menu — browse available plugins, read descriptions, and install with one selection.

**Option B: Install directly**

```
/plugin install kf-claude
```

or

```
/plugin install kf-cli
```

### Step 3: Verify installation

```
/plugin list
```

You should see your installed plugin(s) in the list.

---

> **Note for kf-claude users**: kf-claude requires Docker Desktop and the MCP Toolkit to be running. If you don't want Docker/MCP, install `kf-cli` instead — it has the same commands with no Docker dependency.

## Available Commands

After installation, all plugin commands are namespaced:

**kf-claude** (requires MCP Docker):
- `/kf-claude:capture`, `/kf-claude:youtube-note`, `/kf-claude:idea`, `/kf-claude:publish`, `/kf-claude:article`, `/kf-claude:study-guide`

**kf-cli** (no Docker needed):
- `/kf-cli:capture`, `/kf-cli:youtube-note`, `/kf-cli:idea`, `/kf-cli:publish`, `/kf-cli:article`, `/kf-cli:study-guide`

**flight**:
- `/flight:flight` — Search flights via Trip.com

## Structure

```
zorskill/
├── .claude-plugin/
│   └── marketplace.json    # Plugin registry
├── plugins/
│   ├── kf-claude/          # git submodule → ZorroCheng-MC/kf-claude
│   ├── kf-cli/             # git submodule → ZorroCheng-MC/kf-cli
│   └── flight/             # git submodule → laucw1213/flight-skill
└── README.md
```

## Contributing

ZorCorp welcomes third-party plugin contributions. Open an issue to discuss adding your plugin to the marketplace.

---

**ZorCorp** · [github.com/ZorCorp](https://github.com/ZorCorp) · info@zorcorp.dev

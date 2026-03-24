#!/usr/bin/env node
/**
 * zorskills setup
 * Installs ZorCorp skills to ~/.agents/skills/ and symlinks them into each
 * detected agent (Claude Code, OpenClaw).
 *
 * Runs automatically on: npm install -g @zorcorp/zorskills
 * Run manually:          node scripts/setup.js
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const HOME = os.homedir();
const AGENTS_SKILLS = path.join(HOME, '.agents', 'skills');
const PLUGINS_DIR = path.join(__dirname, '..', 'plugins');

// Agent skill directories to symlink into (only if agent root exists)
const AGENT_DIRS = {
  'claude':   path.join(HOME, '.claude', 'skills'),
  'openclaw': path.join(HOME, '.openclaw', 'skills'),
};

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function pathExists(p) {
  try { fs.lstatSync(p); return true; } catch { return false; }
}

function isSymlink(p) {
  try { return fs.lstatSync(p).isSymbolicLink(); } catch { return false; }
}

function ensureSymlink(target, linkPath, label) {
  if (pathExists(linkPath)) {
    if (isSymlink(linkPath)) {
      fs.unlinkSync(linkPath);
    } else {
      console.log(`  skipped ${label} (exists as real directory)`);
      return false;
    }
  }
  fs.symlinkSync(target, linkPath);
  return true;
}

// Validate plugins directory
if (!fs.existsSync(PLUGINS_DIR)) {
  console.error('plugins/ directory not found.');
  console.error('If installed via npm, submodules may not be included.');
  console.error('Try: git submodule update --init --recursive');
  process.exit(1);
}

const plugins = fs.readdirSync(PLUGINS_DIR).filter(name => {
  const p = path.join(PLUGINS_DIR, name);
  try { return fs.statSync(p).isDirectory() && !name.startsWith('.'); }
  catch { return false; }
});

if (plugins.length === 0) {
  console.error('No plugins found in plugins/. Submodules may not be checked out.');
  console.error('Run: git submodule update --init --recursive');
  process.exit(1);
}

ensureDir(AGENTS_SKILLS);
console.log(`\nInstalling ${plugins.length} ZorCorp skill(s)...\n`);

for (const plugin of plugins) {
  const pluginSrc = path.join(PLUGINS_DIR, plugin);
  const agentsTarget = path.join(AGENTS_SKILLS, plugin);

  // 1. Symlink plugin into ~/.agents/skills/<name>
  if (ensureSymlink(pluginSrc, agentsTarget, `~/.agents/skills/${plugin}`)) {
    console.log(`✓ ~/.agents/skills/${plugin}`);
  }

  // 2. Symlink into each detected agent using relative paths
  for (const [agentName, agentSkillsDir] of Object.entries(AGENT_DIRS)) {
    const agentRoot = path.join(HOME, `.${agentName}`);
    if (!fs.existsSync(agentRoot)) continue;

    ensureDir(agentSkillsDir);

    const linkPath = path.join(agentSkillsDir, plugin);
    const relTarget = path.relative(agentSkillsDir, agentsTarget);

    if (ensureSymlink(relTarget, linkPath, `~/.${agentName}/skills/${plugin}`)) {
      console.log(`  → ${agentName}: ~/.${agentName}/skills/${plugin}`);
    }
  }
}

console.log('\nzorskills setup complete.');
console.log('Claude Code: invoke skills as /skill-name');
console.log('OpenClaw: restart agent to pick up new skills\n');

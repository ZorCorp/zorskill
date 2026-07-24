# How we release ZorCorp skills (`zorskill-dev`)

Quick intro to our plugin marketplace (**zorskill**) so you can ship skill updates yourself.

**The setup, in one line:** each skill lives in its own repo (`ZorCorp/<name>`); the
**zorskill** marketplace bundles them all. A tool called **`zorskill-dev`** keeps the
marketplace in sync — so you only ever work in your own repo.

---

## Releasing an update — the split

### 👉 YOUR part

```bash
# 1. check your plugin's current version (run in your repo root):
jq -r .version .claude-plugin/plugin.json      # e.g. prints 1.3.0

# 2. release the next version — from the repo, or Actions tab → "Release" → Run:
gh workflow run release.yml -f version=1.3.1
```

Pick the next number with semver: **patch** (`1.3.0 → 1.3.1`) for a fix,
**minor** (`1.3.0 → 1.4.0`) for a new feature. That's your whole job.

### 🤖 DONE FOR YOU automatically (you do nothing)

1. Your version is written into `plugin.json`, committed, and tagged
2. The marketplace pointer, versions, and README are updated to match
3. Live in the marketplace within ~30–60 min

You **never** edit `plugin.json`, `marketplace.json`, the README, or open the marketplace repo.

---

## 🛡️ Safety net — a drift scanner watches the marketplace

A scanner runs every 30 min and reconciles each repo against the marketplace, so you
don't have to babysit anything:

- **If you cut a version but the marketplace didn't update** (a hiccup, a missed step)
  → the scanner notices the gap and carries it in automatically. You don't chase it.
- It's **forward-only** (never downgrades a plugin) and **won't publish a broken
  release** — a bad version is skipped, not shipped.
- **The one thing it can't do for you:** it only ships versions you've actually cut with
  `release.yml`. It syncs the marketplace to your repos — it can't decide *when* to
  release. So if you never run `release.yml`, your change stays in your repo and never
  reaches users.

**In short:** run `release.yml` when you want to ship — that's the only step that's truly
yours. Everything after it is automatic, and if anything slips, the scanner catches up
within ~30 min.

---

## Creating a brand-new skill

Create the empty `ZorCorp/<name>` repo, then run `/zorskill-dev:new <name>` from the
monorepo — it scaffolds everything (including the `release.yml` above), so your skill is
release-ready immediately.

## Need it live instantly, not in ~30 min?

`/zorskill-dev:release <name> <x.y.z>` carries it in on the spot.

## When to cut a version

Whenever a change is worth users pulling — a fix, a feature. Not every commit; batch
work-in-progress and release once.

---

Full reference: the `zorskill-dev` SKILL.md.

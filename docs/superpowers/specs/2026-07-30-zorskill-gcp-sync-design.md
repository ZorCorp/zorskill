# zorskill → GCP Skill Registry sync + MC Data Agent — Design

**Date:** 2026-07-30
**Status:** Approved pending user review
**Scope:** One combined system, two planes: (1) automated sync of selected zorskill
plugins to the GCP Agent Platform skill registry; (2) an ADK "MC Data Agent"
deployed to Agent Engine and registered on a Gemini Enterprise (GE) app.

## Goals

- The GCP skill registry always holds the latest **marketplace-released**,
  Gemini-compatible version of each opted-in zorskill plugin — automatically,
  within ~30–60 min of a release, with no human in the sync loop.
- One MC Data Agent (bms2 + gcp-bq skills, wired to the bq-mcp Cloud Run MCP
  endpoints) deployable to any GE app on demand, defaulting to the existing
  default app.
- Extensible: onboarding a future plugin is one `skills.json` entry plus fence
  markers in its SKILL.md — no pipeline changes.

## Non-goals

- Syncing all 10 zorskill plugins (most are Claude-runtime-bound; conversion is
  opt-in per plugin).
- LLM-driven conversion in CI (deterministic transforms only).
- Automating GE app provisioning (the default app already exists).
- RBAC on the data skills (BMS2 Stage 1 = all-access; unchanged here).

## Decisions log (from grilling)

| # | Question | Decision |
|---|----------|----------|
| 1 | Scope split | One combined spec (sync + agent) |
| 2 | Which skills | bms2 + gcp-bq only; pipeline extensible |
| 3 | Conversion | Marker fences in canonical SKILL.md + deterministic strip script; no LLM in CI |
| 4 | GCP project | Zorro-test now; **aiexpense later** (APIs not yet enabled) — everything parameterized via org variables; registry location us-central1 |
| 5 | CI auth | Workload Identity Federation (keyless), dedicated deployer SA |
| 6 | Agent shape | One ADK "MC Data Agent" with both skills + both bq-mcp MCP toolsets |
| 7 | GE app | Default app exists; `workflow_dispatch` input overrides target |
| 8 | Sync trigger | **Second job in the existing `plugin-drift.yml`** (every 30 min, `needs: drift`) — not release tags, not a separate schedule. Rationale: (a) drift auto-fix already runs every 30 min and pushes with `GITHUB_TOKEN`, and such pushes do **not** fire other workflows' push triggers (GitHub recursion protection), so a push-triggered sync would never run; (b) same-run sequencing makes "drift fix first, GCP packaging next" structural rather than a timing arrangement |
| 9 | Source of truth | `marketplace.json` version (human/check-gated release flow blesses it) — the registry never ships a version the marketplace hasn't carried in |
| 10 | Agent deploy trigger | Path-filtered auto-deploy (`agents/mc-data-agent/**` → default app) + manual `workflow_dispatch(ge_app, gcp_project)` wrapped as `/zorskill-dev:deploy-agent` |

## Architecture

```
ZorCorp/bms2, ZorCorp/gcp-bq            ZorCorp/zorskill (this repo)
  SKILL.md with fence markers             .github/workflows/plugin-drift.yml
        │                                   job 1: drift  (existing, unchanged)
        │  cloned at marketplace-           job 2: gcp-sync (NEW, needs: drift)
        │  blessed version                .github/workflows/agent-deploy.yml (NEW)
        └────────────────────────────►    tools/skill2gemini/   (NEW)
                                            convert.sh, skills.json, bootstrap.sh,
                                            tests/fixtures
                                          agents/mc-data-agent/ (NEW, ADK Python)
                                                  │
                                        WIF (keyless) → deployer SA
                                                  ▼
                        GCP project = ${GCP_PROJECT}  (Zorro-test → aiexpense)
                          Skill Registry (us-central1): skills `bms2`, `gcp-bq`
                          Agent Engine: mc-data-agent
                          GE app: default, overridable per dispatch
                        Agent SA → run.invoker on bq-mcp Cloud Run
                          (cross-project: gen-lang-client-0674348445, asia-east2)
```

## Components

### 1. Marker fences (one-time edit in each skill repo's SKILL.md)

- `<!-- claude-only -->` … `<!-- /claude-only -->` — stripped for Gemini.
  Wraps: Artifact/chart sections, `artifact-design` cross-references,
  `.claude-plugin/plugin.json` version note, Claude Code-specific asides.
- `<!-- gemini-only\n…content…\n-->` — unwrapped (content surfaces) for Gemini.
  Carries replacements, e.g. "Return results as a Markdown table."
- Unfenced content is shared. HTML comments are invisible to Claude Code users.

### 2. `tools/skill2gemini/convert.sh` — deterministic transformer

- Input: path to a checked-out skill repo; output: `dist/<skill>.zip` + manifest.
- Transform: strip `claude-only`, unwrap `gemini-only`, include only `SKILL.md`
  + `references/` (drop `.claude-plugin/`, `CLAUDE.md`, `PUBLISH.md`, `.github/`,
  `deploy/`, `.git`).
- Validate (fail non-zero on violation): frontmatter has `name` (≤64 chars,
  `[a-z0-9-]`, not `gcp-*`) and `description` (≤1024 chars); body ≤500k chars;
  no symlinks; dir depth ≤8; no duplicate filenames; zip ≤10 MB (warn >500 KB —
  console-upload ceiling).
- Pure shell/awk; identical behavior locally and in CI.

### 3. `tools/skill2gemini/skills.json` — opt-in scope

```json
[
  {"plugin": "bms2",   "repo": "ZorCorp/bms2",   "display_name": "BMS2"},
  {"plugin": "gcp-bq", "repo": "ZorCorp/gcp-bq", "display_name": "GCP Billing"}
]
```

- Future monorepo plugins use `"path": "plugins/<name>"` instead of `"repo"`
  (version read from that directory's `plugin.json`); schema supports both forms
  from day one.
- Deliberately not inferred from `marketplace.json`: GCP sync is opt-in because
  most plugins are not Gemini-portable. Onboarding = one entry + fences.

### 4. `gcp-sync` job (appended to `plugin-drift.yml`)

- `needs: drift`; same 30-min schedule + existing `workflow_dispatch`; adds a
  `dry_run` dispatch input. Permissions: `id-token: write` (WIF), `contents: read`.
- Per skill in `skills.json`:
  1. Checkout fresh `main` (post-drift-push state); read `marketplace.json`
     version **V**.
  2. `GET …/skills/<id>`; extract stamped version from `description` suffix
     `(vX.Y.Z)`.
  3. Stamp == V → no-op (`in sync @ V`).
  4. Else resolve repo state for V: tag `vV` if present, else default-branch tip
     **only if** its `plugin.json` version == V; otherwise **HELD** (see error
     handling).
  5. `convert.sh` → base64 zip.
  6. `PATCH …/skills/<id>?updateMask=description,zippedFilesystem` — description
     = converted frontmatter description + ` (vV)`. Stamp and payload travel in
     one atomic call.
  7. Poll the LRO; then `GET` and assert async validation passed.
  8. Emit per-skill status line to the job summary.
- Config via org-level GitHub variables: `GCP_PROJECT`, `GCP_REGION`
  (us-central1), `WIF_PROVIDER`, `GCP_DEPLOYER_SA`. aiexpense migration =
  rerun bootstrap there + update variables; zero code change.
- CI never calls `CreateSkill` — skill IDs are immutable/permanently reserved,
  so initial creation stays a deliberate human step (bootstrap).

### 5. `agents/mc-data-agent/` + `agent-deploy.yml`

- ADK Python agent: Master Concept data-domain system instruction; MCP toolsets
  for `https://bq-mcp-…run.app/mcp/bms2` and the billing toolset endpoint (exact
  path as documented in the gcp-bq plugin's SKILL.md); both
  registry skills attached by resource name
  (`projects/$GCP_PROJECT/locations/$GCP_REGION/skills/{bms2,gcp-bq}`).
- `agent-deploy.yml` triggers: push to `main` touching `agents/mc-data-agent/**`
  (deploys to the **default** GE app) and `workflow_dispatch` with inputs
  `ge_app` (default: org variable `GE_DEFAULT_APP`) and `gcp_project` (default:
  `GCP_PROJECT`).
- Steps: WIF auth → deploy to Agent Engine → register/update the agent on the
  target GE app → smoke ping. Deploy and register are sequential; a deploy
  failure aborts before registration.
- The agent's runtime SA needs `run.invoker` on the `bq-mcp` Cloud Run service
  in `gen-lang-client-0674348445` (cross-project) — granted once by bootstrap.
- **Implementation-plan gate:** the GE-app registration API is preview-stage;
  the implementation plan must pin the exact current endpoint/SDK call against
  live docs before code is written, and isolate it in one workflow step.

### 6. `/zorskill-dev:deploy-agent` command (zorskill-dev plugin)

- Thin wrapper: `gh workflow run agent-deploy.yml -f ge_app=<arg-or-empty>`,
  then `gh run watch`. Conversational entry point with the "default app if not
  specified" semantics; CI remains the single executor (auditable, WIF-scoped).

### 7. `tools/skill2gemini/bootstrap.sh` — one-time per project (human-run)

- Enables required APIs (`aiplatform.googleapis.com`,
  `discoveryengine.googleapis.com`, plus any the pinned GE registration API
  documents); creates WIF pool + provider trusted for `ZorCorp/zorskill`; creates
  deployer SA with skill-registry + Agent Engine + GE registration roles;
  performs initial `CreateSkill` for `bms2` and `gcp-bq`; grants the agent SA
  cross-project `run.invoker` on bq-mcp; prints the GitHub org-variable values.
- Rerunnable (idempotent checks) — the aiexpense migration path.

## Error handling

- **Per-skill isolation:** each skill has its own try/catch; one failure never
  blocks others. Job fails at the end if any skill errored; the summary table
  shows `in sync @ v…` / `synced v… → v…` / `HELD: reason` / `FAILED: reason`.
- **Holds, not guesses:** no repo state matching V → `HELD` with instructions;
  never "sync master anyway". Drift job failed → `gcp-sync` skipped (`needs:`);
  the registry keeps serving the last blessed version.
- **Atomic stamp:** version stamp rides in the same PATCH as the payload — the
  stamp can never claim an un-uploaded version.
- **Async validation asserted:** LRO completion + follow-up GET; a rejected
  payload fails the run with Google's validation error in the summary.
- **Self-healing:** console hand-edits corrupt the stamp → reads as drift →
  next run rewrites from marketplace truth. Rollback = revert the marketplace
  version; registry-side revisions are a second net.
- **Agent plane:** sequential deploy → register; idempotent re-runs; failed
  deploy leaves the GE app on the previous agent version.

## Security / IAM

- Keyless CI (WIF); no long-lived credentials in GitHub. Deployer SA scoped to
  skill-registry write + Agent Engine deploy + GE registration in
  `${GCP_PROJECT}` only.
- Agent runtime SA: `run.invoker` on bq-mcp only. Data-plane authz unchanged
  (bq-mcp already fronts read-only BigQuery with a 5 GB scan cap).
- Skill content rule (from registry guidance): no credentials/sensitive data in
  SKILL.md frontmatter — `convert.sh` output is reviewable in the run summary.

## Testing

1. **Golden tests for `convert.sh`:** fixture skill dirs (fences, oversized
   description, symlink, duplicate filenames, >8 depth) with expected outputs;
   assert each validation rule rejects. PR check on
   `tools/skill2gemini/**` changes.
2. **`dry_run` dispatch input:** full pipeline (clone → convert → validate →
   diff vs registry) printing the would-be PATCH without sending. Also the
   acceptance gate when onboarding a future skill.
3. **End-to-end acceptance (manual, once per project):** dry-run → real run
   against Zorro-test → verify both skills in console; deploy agent to default
   GE app → smoke-test known-answer questions ("2026 revenue by region" → bms2
   tools; a billing-cost query → gcp-bq) and confirm tool calls reach bq-mcp.

## Extensibility (confirmed)

- Skills are independent rows: own registry ID, own fences, own reconcile
  iteration; adding a skill cannot affect existing ones. Registry IDs are
  per-project; current plugin names satisfy Google ID rules.
- Monorepo plugins supported via `path` entries (schema ready from day one).
- Caveat (editorial, by design): conversion guarantees structural validity, not
  usefulness — a Claude-runtime-bound plugin converts to a valid-but-inert
  Gemini skill unless its fences/replacement text are written thoughtfully.

## Out of scope / later

- aiexpense cutover (rerun bootstrap + flip org variables) once its APIs are
  enabled and Zorro-test testing passes.
- RBAC stages for bms2 (tracked in that repo's `references/rbac.md`).
- Additional plugins beyond bms2/gcp-bq.

---
description: Bulk AI-powered tagging for existing notes to enable Bases filtering
argument-hint: [folder-path or file-pattern]
allowed-tools:
  - Read(*)
  - Edit(*)
  - Glob(*)
  - Bash(*)
---

## Context

- **Today's Date:** !`date "+%Y-%m-%d"`
- **Target:** `$ARGUMENTS` (defaults to all .md files if not specified)

## Tag Taxonomy Reference

Use the same taxonomy as `/capture`:

**Content Types:** idea, video, article, study-guide, repository, reference, project
**Topics:** AI, Claude, Gemini, product, marketing, projects, workflow, architecture, design, UI-UX, coding, productivity, knowledge-management, development, learning, research, writing, tools, business, automation, data-science, web-development, personal-growth, finance
**Status:** inbox, processing, evergreen, published, archived, needs-review
**Metadata:** high-priority, quick-read, deep-dive, technical, conceptual, actionable, tutorial, inspiration

## Your Task

### Step 1: Discover Files to Tag

```bash
# If user provided pattern:
find . -name "$ARGUMENTS" -type f

# If no arguments (tag everything):
find . -name "*.md" -type f -not -path "./.obsidian/*" -not -path "./.claude/*"
```

### Step 2: Process Each File

For each discovered file:

1. **Read the file content**
2. **Analyze existing frontmatter**:
   - Check if `tags:` field exists
   - Check if tags are already comprehensive (5+ tags from taxonomy)

3. **Skip if already well-tagged** (has 5+ taxonomy-compliant tags)

4. **Analyze content** to determine:
   - Content type (from filename, existing tags, content)
   - Main topics (2-4 from content analysis)
   - Status (infer from content or default to `evergreen` for old notes)
   - Metadata characteristics

5. **Generate enhanced tag array**:
   ```yaml
   tags: [{content-type}, {topic1}, {topic2}, {topic3}, {status}, {metadata}]
   ```

6. **Update frontmatter** while preserving existing data:
   ```yaml
   ---
   title: "{existing or generated}"
   tags: [{enhanced-tag-array}]
   date: "{existing or file creation date}"
   type: "{content-type}"
   status: "{status}"
   # preserve any other existing fields
   ---
   ```

### Step 3: Report Progress

After processing each batch of 5-10 files, report:
```
✅ Tagged 10 files:
   - 3 ideas tagged with [idea, productivity, ...]
   - 2 videos tagged with [video, AI, learning, ...]
   - 5 articles tagged with [article, development, ...]

📊 Progress: 10/47 files processed
🏷️  Total tags added: 73 tags
```

### Step 4: Summary Report

After all files processed:

```markdown
# Bulk Tagging Report

## Summary
- **Files processed:** 47
- **Files updated:** 43
- **Files skipped:** 4 (already well-tagged)
- **Total tags added:** 312
- **Average tags per note:** 7.3

## Tag Distribution

### By Content Type
- idea: 15 notes
- video: 8 notes
- article: 12 notes
- study-guide: 6 notes
- repository: 2 notes

### By Topic
- AI: 23 notes
- productivity: 18 notes
- knowledge-management: 15 notes
- development: 12 notes
- learning: 10 notes

### By Status
- inbox: 12 notes
- evergreen: 28 notes
- published: 7 notes

## Bases Filtering Suggestions

You can now create Bases views like:
1. **AI Learning Pipeline**: `type = video AND topic = AI AND status = inbox`
2. **Quick Wins**: `metadata = quick-read AND priority = high-priority`
3. **Technical Deep Dives**: `metadata = technical AND metadata = deep-dive`
4. **Actionable Items**: `metadata = actionable AND status != archived`

## Next Steps
1. Review auto-tagged notes in Obsidian
2. Create Bases views using these tags
3. Refine tags manually if needed
4. Run `/bulk-auto-tag` periodically for new notes
```

## Important Rules

1. **Preserve existing data**: Never delete user-added tags or properties
2. **Merge intelligently**: Combine AI tags with existing tags (deduplicate)
3. **Be conservative**: If uncertain about content type, default to `reference`
4. **Handle errors gracefully**: Skip files with invalid frontmatter, report errors
5. **Respect user intent**: If a file has explicit tags, enhance rather than replace

## Example Transformations

### Before (minimal tags):
```yaml
---
tags: [idea]
date: 2025-09-15
---

# AI-powered tagging
Use Claude to auto-tag notes for better organization
```

### After (enhanced tags):
```yaml
---
title: "AI-powered tagging"
tags: [idea, AI, knowledge-management, tools, evergreen, actionable, technical]
date: 2025-09-15
type: idea
status: evergreen
priority: medium
---

# AI-powered tagging
Use Claude to auto-tag notes for better organization
```

## Performance Considerations

- Process files in batches of 10
- Show progress every batch
- Allow user to cancel with Ctrl+C
- Estimate time for large vaults: ~2-3 seconds per file

## Safety Features

1. **Dry run mode** (optional): Show what would be changed without modifying files
2. **Backup reminder**: Remind user to commit to git before bulk operations
3. **Undo support**: Provide git commands to rollback if needed

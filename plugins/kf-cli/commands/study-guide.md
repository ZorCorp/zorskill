---
description: Generate comprehensive study guide with AI-powered smart tagging from any content source
argument-hint: [content-source] (file path, URL, or direct text to create study guide from)
allowed-tools:
  - Bash(*)
  - Read(*)
  - Write(*)
  - WebFetch(*)
---

## Task

Create a study guide note using CLI tools (no MCP/Docker required).

**⚠️ You MUST use the Write tool to save the file to the vault!**

**Input**: `$ARGUMENTS` (file path, URL, or direct text)
**Operation**: Study guide creation
**Today's Date**: Run `date "+%Y-%m-%d"` to get current date

## Process

1. Get today's date: `date "+%Y-%m-%d"`
2. Fetch content:
   - **URL**: Use `WebFetch` to retrieve the page content
   - **File path**: Use `Read` tool to read the file
   - **Direct text**: Use the provided text directly
3. **Read template FIRST**:
   ```bash
   KFCLI_TEMPLATES=$(find "$HOME/.claude/plugins" -maxdepth 6 -path "*/kf-cli/templates" -type d 2>/dev/null | head -1)
   cat "$KFCLI_TEMPLATES/study-guide-template.md"
   ```
4. Analyze content complexity, topics, and learning requirements
5. Apply AI-powered smart tagging (using tag taxonomy)
6. Generate structured learning plan with objectives and assessments
7. Replace all `{{PLACEHOLDER}}` with actual values
8. Save note using Write tool to `${KF_VAULT_PATH:-$HOME/Documents/Obsidian/myrag}/notes/{filename}`

## Tag Taxonomy Reference

**Topics:** AI, productivity, knowledge-management, development, learning, research, writing, tools, business, design, automation, data-science, web-development, personal-growth, finance
**Status:** processing (default for study guides - active learning)
**Metadata:** deep-dive, technical, conceptual, actionable, tutorial

## Expected Output

A comprehensive study guide with:
- Proper frontmatter (title, tags, source, date, type, status, difficulty, estimated-time, priority)
- Overview with subject and generated date
- Learning objectives (specific, measurable, checkboxed)
- Study plan with time estimates and difficulty level
- Structured content breakdown (weekly/modular)
- Study strategies (material-specific and active learning techniques)
- Self-assessment questions (intermediate and final)
- Progress tracking section
- Related notes and connections
- Tags analysis with filtering suggestions
- Semantic search suggestions

**File naming format**: `[date]-[topic-name]-study-guide.md`
**Tag count**: 6-8 tags total
**Status**: Always `processing` (active study material)

## Examples

**Input (URL)**: "https://example.com/machine-learning-course"
→ `2025-10-28-machine-learning-study-guide.md`

**Input (File)**: "react-advanced-patterns.md"
→ `2025-10-28-react-advanced-study-guide.md`

**Input (Text)**: "Deep dive into distributed systems architecture"
→ `2025-10-28-distributed-systems-study-guide.md`

## After Saving: Update Wiki Index

Once the note file is written, update the wiki immediately:

1. Read the saved note's `tags` list from its YAML frontmatter
2. Read `CLAUDE.md` in the vault root and find the **Tag → Topic Mapping** table
3. For each tag, look up the matching wiki file path in the table
4. For each matched wiki file:
   - If it doesn't exist yet, create it with a `# [Topic]` heading and a `## Notes` section
   - Append: `- [[notes/FILENAME|TITLE]] — one-sentence description`
5. If any matched topic file was newly created, add an entry for it in `wiki/_master-index.md`
6. If no tags match the table, route to the most relevant existing topic based on the note's content

**This step is required after every capture. Do not skip it.**

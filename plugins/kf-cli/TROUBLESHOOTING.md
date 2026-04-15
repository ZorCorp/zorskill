# kf-cli Troubleshooting Guide

Common issues encountered during real testing, with quick fixes.

---

## 1. yt-dlp Errors

**Problem:** Video unavailable, geo-restricted, or rate-limited when fetching YouTube metadata.

**Cause:** Outdated yt-dlp binary, or the video itself is restricted/private.

**Fix:**
```bash
brew upgrade yt-dlp
```
If the video is geo-restricted or private, try a different video. Rate limiting resolves after waiting a few minutes.

---

## 2. gh CLI Not Authenticated

**Problem:** GitHub CLI commands fail with authentication errors.

**Cause:** `gh` has not been logged in on this machine.

**Fix:**
```bash
gh auth login
```
Follow the interactive prompts to authenticate via browser or token.

---

## 3. Transcript Fetch Fails

**Problem:** YouTube transcript extraction fails or `uvx` command not found.

**Cause:** `uv` (and therefore `uvx`) is not installed, or `youtube_transcript_api` cannot retrieve the transcript for that video.

**Fix:**
```bash
brew install uv
```
Some videos have no transcript available (auto-generated or manual). There is no workaround for those.

---

## 4. WebFetch Fails

**Problem:** WebFetch returns 404, times out, or hits an auth-required page.

**Cause:** The target URL is behind a login wall, has been removed, or blocks automated requests.

**Fix:** Fall back to `curl` as an alternative:
```bash
curl -sL "https://example.com/page" | head -200
```
For paywalled content, manually copy the text and use `/capture` with the pasted content instead.

---

## 5. Publish Script Fails

**Problem:** `/publish` errors out with "repository not found" or git push is rejected.

**Cause:** The `sharehub` repository is not cloned locally, or git authentication has expired.

**Fix:**
```bash
# Clone sharehub if missing
cd ~/Dev && git clone https://github.com/<your-user>/<your-sharehub-repo>.git

# If push is rejected, check auth
gh auth status
```
Ensure the local `sharehub` repo is on the correct branch and has no conflicting changes.

---

## 6. Share URL Too Long

**Problem:** Shared URLs are truncated or fail to open in browsers.

**Cause:** The share mechanism URL-encodes the entire note content. Notes over ~4000 characters exceed browser URL length limits.

**Fix:** Use `/publish` instead of `/share` for longer notes. Publishing stores the content server-side and produces a short, stable URL.

---

## 7. Template Not Found

**Problem:** Commands fail with "template not found" or reference missing files.

**Cause:** Symlinks in `kf-cli/templates/` are broken, typically after a reinstall or path change.

**Fix:**
```bash
# Verify symlinks
ls -la "${KF_VAULT_PATH:-$HOME/Documents/Obsidian/myrag}/kf-cli/templates/"

# Re-run setup if broken
# or manually re-link templates from the source
```

---

## 8. Gemini Image Generation Fails

**Problem:** Hero image generation returns an API error or produces no output.

**Cause:** `GEMINI_API_KEY` is missing or the quota for the Gemini API has been exceeded.

**Fix:**
```bash
# Check if the key is set
echo $GEMINI_API_KEY

# If missing, add to your shell profile
echo 'export GEMINI_API_KEY="your-key-here"' >> ~/.zshrc
source ~/.zshrc
```
For quota issues, wait for the quota to reset or check usage at the Google AI Studio console.

---

## 9. Background Agent Permission Denied

**Problem:** Background agents spawned with `run_in_background` fail because Bash tool is not approved.

**Cause:** Background agent threads cannot prompt for interactive tool approval. The parent session must have already approved Bash.

**Fix:** Run any Bash command in the main (foreground) session first to trigger the approval prompt. Once approved, background agents inherit the permission. Use `mode: "bypassPermissions"` when spawning background agents that need Bash or Write access.

---

## 10. Tags Outside Taxonomy

**Problem:** LLM-generated tags do not match the predefined taxonomy in `CLAUDE.md`.

**Cause:** The LLM occasionally generates semantically similar but non-standard tags (e.g., "machine-learning" instead of "AI").

**Fix:** This is expected variance. The tag taxonomy is a guide, not a strict constraint. Manually correct tags in the note frontmatter if consistency matters for your workflows. The predefined taxonomy is listed in the vault's `CLAUDE.md` under "Tag Taxonomy."

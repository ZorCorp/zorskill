---
description: Share note via URL-encoded link (Plannotator-style, no server storage)
argument-hint: [filename] (note to share, e.g., my-note.md)
allowed-tools:
  - Bash(*)
  - Read(*)
  - Task(*)
---

## Context

- **Current Directory:** `$PWD`
- **Config File:** `.claude/config.local.json` (created by `/kf-cli:setup`)

## Task

Generate a shareable URL for a note using Base64 + zlib compression.

**Input**: `$ARGUMENTS` (filename with or without .md extension)

## Implementation

**IMPORTANT: Always spawn an agent for this task.**

Use the Task tool with these exact parameters:

```
Task tool call:
  subagent_type: "general-purpose"
  description: "Generate shareable URL"
  prompt: |
    Generate a shareable URL for the note "$ARGUMENTS".

    Steps:
    0. Determine the vault path:
       - Read .claude/config.local.json from the current working directory ($PWD)
       - Extract the "vault_path" value
       - If the config file doesn't exist, fall back to $PWD as the vault path

    1. Read the note file from {vault_path}/$ARGUMENTS
       (add .md extension if missing)

    2. Write the note content to a temp file, then run the Python script.
       IMPORTANT: Use a temp file to avoid shell escaping issues.

    ```bash
    python3 << 'PYTHON_SCRIPT'
    import json, zlib, base64, subprocess, sys, os

    # Read vault config for share URL (optional override)
    import os
    SHARE_BASE_URL = os.environ.get("KF_SHARE_BASE_URL", "https://example.com/share")
    config_path = os.path.join(os.environ.get("PWD", os.getcwd()), ".claude", "config.local.json")
    if os.path.exists(config_path):
        try:
            with open(config_path) as f:
                config = json.load(f)
            if config.get("share_base_url"):
                SHARE_BASE_URL = config["share_base_url"]
        except Exception:
            pass

    # Read content from temp file
    with open('/tmp/share_note.md', 'r') as f:
        content = f.read()

    # CRC32 matching JavaScript's charCodeAt & 0xFF implementation (UTF-16 code units)
    def crc32_str(s):
        table = []
        for i in range(256):
            c = i
            for _ in range(8):
                c = (0xEDB88320 ^ (c >> 1)) if (c & 1) else (c >> 1)
            table.append(c & 0xFFFFFFFF)
        crc = 0xFFFFFFFF
        for ch in s:
            cp = ord(ch)
            if cp < 0x10000:
                code_units = [cp]
            else:
                cp -= 0x10000
                code_units = [0xD800 + (cp >> 10), 0xDC00 + (cp & 0x3FF)]
            for unit in code_units:
                crc = table[(crc ^ (unit & 0xFF)) & 0xFF] ^ (crc >> 8)
        return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF

    # Create structure with checksum
    data = {"p": content, "a": []}
    payload = json.dumps({"p": content, "a": []}, ensure_ascii=False, separators=(',', ':'))
    data["_crc"] = crc32_str(payload)

    # Compress and encode
    json_str = json.dumps(data, ensure_ascii=False)
    compressed = zlib.compress(json_str.encode('utf-8'))
    encoded = base64.urlsafe_b64encode(compressed).decode('utf-8')

    # Generate URL
    url = f"{SHARE_BASE_URL}#{encoded}"
    url_len = len(url)

    print(url)
    print(f"\n--- URL length: {url_len} chars ---", file=sys.stderr)

    if url_len > 8000:
        print(f"WARNING: URL is {url_len} chars. URLs over 8000 chars are often truncated by messaging apps.", file=sys.stderr)
        print("Consider using /publish instead for large notes.", file=sys.stderr)
    elif url_len > 4000:
        print(f"CAUTION: URL is {url_len} chars. Some platforms may truncate this.", file=sys.stderr)
        print("Tip: Share via code block or plain text to avoid truncation.", file=sys.stderr)

    # Copy to clipboard
    subprocess.run(['pbcopy'], input=url.encode(), check=True)

    # Cleanup
    os.unlink('/tmp/share_note.md')
    PYTHON_SCRIPT
    ```

    3. Return the shareable URL and confirm it was copied to clipboard.
       Include the URL length and any warnings from stderr output.

    If the URL is over 4000 chars, warn the user about potential truncation.
    If over 8000 chars, strongly recommend using `/publish` instead.
```

## Features

- **No server storage**: Content lives entirely in the URL
- **Compression**: zlib reduces URL length
- **Integrity check**: CRC32 checksum detects URL corruption from truncation
- **Annotations**: Recipients can add comments and re-share
- **Compatible**: Same format as Plannotator

## Examples

```
/kf-cli:share my-note.md
/kf-cli:share paydollar-test-plan
```

## Limitations

- URLs over ~4000 chars may be truncated by messaging apps (Slack, WhatsApp, email)
- URLs over ~8000 chars will almost certainly be truncated - use `/publish` instead
- Always share URLs in code blocks or plain text to minimize truncation risk

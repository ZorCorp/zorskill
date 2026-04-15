#!/bin/bash
# Post-publish verification for sharehub
# Checks: HTTP status, content type, image availability, all links
# Usage: ./verify-publish.sh NOTE_FILE [VAULT_PATH]

set -e

NOTE_FILE="$1"
VAULT_PATH="${2:-$(pwd)}"
ERRORS=0
WARNINGS=0

# Read config
CONFIG_FILE="$VAULT_PATH/.claude/config.local.json"
if [[ -f "$CONFIG_FILE" ]]; then
    SHAREHUB_URL=$(jq -r '.sharehub_url // empty' "$CONFIG_FILE")
fi
SHAREHUB_URL="${SHAREHUB_URL:-}"
if [[ -z "$SHAREHUB_URL" ]]; then
    echo "❌ SHAREHUB_URL not set"
    exit 1
fi

# Add .md extension if not provided
if [[ ! "$NOTE_FILE" =~ \.md$ ]]; then
    NOTE_FILE="${NOTE_FILE}.md"
fi

# Build URL (encode spaces as %20)
URL_FILE=$(echo "${NOTE_FILE%.md}.html" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))")
PUBLISHED_URL="$SHAREHUB_URL/documents/$URL_FILE"

echo "🔍 Post-publish verification"
echo "   Note: $NOTE_FILE"
echo "   URL:  $PUBLISHED_URL"
echo ""

# ── Check 1: HTTP 200 ──
echo "1️⃣  HTTP Status..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$PUBLISHED_URL" 2>/dev/null || echo "000")
if [[ "$HTTP_STATUS" == "200" ]]; then
    echo "   ✅ HTTP 200 OK"
else
    echo "   ❌ HTTP $HTTP_STATUS — page not reachable"
    ERRORS=$((ERRORS + 1))
fi

# ── Check 2: Content is HTML (not raw markdown) ──
echo "2️⃣  Content type..."
CONTENT_TYPE=$(curl -sI "$PUBLISHED_URL" 2>/dev/null | grep -i "^content-type:" | head -1 | tr -d '\r')
if echo "$CONTENT_TYPE" | grep -qi "text/html"; then
    echo "   ✅ Served as HTML"
    
    # Extra check: verify it's actually rendered HTML, not raw markdown
    FIRST_TAG=$(curl -s "$PUBLISHED_URL" 2>/dev/null | head -5 | grep -c "<\!DOCTYPE\|<html\|<head" || true)
    if [[ "$FIRST_TAG" -gt 0 ]]; then
        echo "   ✅ Jekyll rendering confirmed (DOCTYPE/html tags present)"
    else
        echo "   ⚠️  Content-type is HTML but page may not be properly rendered"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ❌ Not HTML: $CONTENT_TYPE"
    ERRORS=$((ERRORS + 1))
fi

# Fetch the rendered HTML once for reuse
HTML_CONTENT=$(curl -s "$PUBLISHED_URL" 2>/dev/null || true)

# ── Check 3: Images ──
echo "3️⃣  Image references..."

if [[ -f "$VAULT_PATH/$NOTE_FILE" ]]; then
    # Get all image refs from markdown (local only, skip http URLs)
    IMAGE_REFS=$(grep -o '!\[[^]]*\]([^)]*\.\(jpg\|jpeg\|png\|gif\|svg\|webp\))' "$VAULT_PATH/$NOTE_FILE" 2>/dev/null | sed 's/.*(\(.*\))/\1/' | grep -v '^https\?://' || true)
    
    if [[ -z "$IMAGE_REFS" ]]; then
        echo "   ℹ️  No local images in source note"
    else
        IMG_COUNT=0
        IMG_OK=0
        
        while IFS= read -r IMG_PATH; do
            [[ -z "$IMG_PATH" ]] && continue
            IMG_COUNT=$((IMG_COUNT + 1))
            
            CLEAN_PATH="${IMG_PATH#./}"
            CLEAN_PATH="${CLEAN_PATH#../}"
            IMG_URL="$SHAREHUB_URL/$CLEAN_PATH"
            IMG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$IMG_URL" 2>/dev/null || echo "000")
            
            if [[ "$IMG_STATUS" == "200" ]]; then
                echo "   ✅ $CLEAN_PATH"
                IMG_OK=$((IMG_OK + 1))
            else
                echo "   ❌ $CLEAN_PATH (HTTP $IMG_STATUS)"
                ERRORS=$((ERRORS + 1))
            fi
        done <<< "$IMAGE_REFS"
        
        echo "   📊 Source images: $IMG_OK/$IMG_COUNT OK"
    fi
    
    # Check images in rendered HTML
    HTML_IMGS=$(echo "$HTML_CONTENT" | grep -o 'src="[^"]*\.\(jpg\|jpeg\|png\|gif\|svg\|webp\)"' | sed 's/src="//;s/"$//' | grep -v '^https\?://' || true)
    
    if [[ -n "$HTML_IMGS" ]]; then
        echo ""
        echo "   Rendered HTML images..."
        while IFS= read -r IMG_SRC; do
            [[ -z "$IMG_SRC" ]] && continue
            
            if [[ "$IMG_SRC" =~ ^/ ]]; then
                IMG_URL="$SHAREHUB_URL$IMG_SRC"
            else
                IMG_URL="$SHAREHUB_URL/documents/$IMG_SRC"
            fi
            
            IMG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$IMG_URL" 2>/dev/null || echo "000")
            
            if [[ "$IMG_STATUS" == "200" ]]; then
                echo "   ✅ $IMG_SRC"
            else
                echo "   ❌ $IMG_SRC (HTTP $IMG_STATUS)"
                ERRORS=$((ERRORS + 1))
            fi
        done <<< "$HTML_IMGS"
    fi
else
    echo "   ⚠️  Source note not found — skipping source image check"
    WARNINGS=$((WARNINGS + 1))
fi

# ── Check 4: All links ──
echo ""
echo "4️⃣  Links..."

# Extract all links from rendered HTML: <a href="...">
ALL_LINKS=$(echo "$HTML_CONTENT" | grep -o 'href="[^"]*"' | sed 's/href="//;s/"$//' | sort -u || true)

# Also extract links from source markdown: [text](url)
if [[ -f "$VAULT_PATH/$NOTE_FILE" ]]; then
    MD_LINKS=$(grep -o '\[[^]]*\]([^)]*)' "$VAULT_PATH/$NOTE_FILE" 2>/dev/null | sed 's/.*(\(.*\))/\1/' | grep -v '^#' || true)
    ALL_LINKS=$(printf "%s\n%s" "$ALL_LINKS" "$MD_LINKS" | sort -u)
fi

LINK_COUNT=0
LINK_OK=0
LINK_FAIL=0
LINK_SKIP=0

while IFS= read -r LINK; do
    [[ -z "$LINK" ]] && continue
    
    # Skip anchors, javascript, mailto, tel
    if [[ "$LINK" =~ ^#|^javascript:|^mailto:|^tel:|^data: ]]; then
        continue
    fi
    
    # Skip image files (already checked in step 3)
    if [[ "$LINK" =~ \.(jpg|jpeg|png|gif|svg|webp)$ ]]; then
        continue
    fi
    
    # Skip CSS/JS framework resources (not content links)
    if [[ "$LINK" =~ cdn\.jsdelivr|code\.jquery|fonts\.googleapis|fonts\.gstatic|cdnjs\.cloudflare ]]; then
        continue
    fi
    
    LINK_COUNT=$((LINK_COUNT + 1))
    
    # Make absolute URL for relative links
    if [[ "$LINK" =~ ^/ ]]; then
        CHECK_URL="$SHAREHUB_URL$LINK"
    elif [[ ! "$LINK" =~ ^https?:// ]]; then
        CHECK_URL="$SHAREHUB_URL/documents/$LINK"
    else
        CHECK_URL="$LINK"
    fi
    
    # Check with timeout (3s per link to avoid hanging)
    LINK_STATUS=$(curl -sL -o /dev/null -w "%{http_code}" --max-time 5 "$CHECK_URL" 2>/dev/null || echo "000")
    
    if [[ "$LINK_STATUS" == "200" || "$LINK_STATUS" == "301" || "$LINK_STATUS" == "302" ]]; then
        LINK_OK=$((LINK_OK + 1))
    elif [[ "$LINK_STATUS" == "000" ]]; then
        echo "   ⚠️  Timeout: $LINK"
        LINK_SKIP=$((LINK_SKIP + 1))
        WARNINGS=$((WARNINGS + 1))
    elif [[ "$LINK_STATUS" == "403" ]]; then
        # Some sites block curl (e.g. YouTube) — warn, don't error
        echo "   ⚠️  Blocked (403): $LINK"
        LINK_SKIP=$((LINK_SKIP + 1))
        WARNINGS=$((WARNINGS + 1))
    elif [[ "$LINK_STATUS" == "429" ]]; then
        echo "   ⚠️  Rate limited (429): $LINK"
        LINK_SKIP=$((LINK_SKIP + 1))
        WARNINGS=$((WARNINGS + 1))
    else
        echo "   ❌ HTTP $LINK_STATUS: $LINK"
        LINK_FAIL=$((LINK_FAIL + 1))
        ERRORS=$((ERRORS + 1))
    fi
done <<< "$ALL_LINKS"

if [[ $LINK_FAIL -eq 0 && $LINK_SKIP -eq 0 ]]; then
    echo "   ✅ All $LINK_COUNT links OK"
elif [[ $LINK_FAIL -eq 0 ]]; then
    echo "   📊 Links: $LINK_OK OK, $LINK_SKIP skipped (timeout/blocked) out of $LINK_COUNT"
else
    echo "   📊 Links: $LINK_OK OK, $LINK_FAIL broken, $LINK_SKIP skipped out of $LINK_COUNT"
fi

# ── Summary ──
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    echo "✅ All checks passed!"
    echo "VERIFIED_URL=$PUBLISHED_URL"
elif [[ $ERRORS -eq 0 ]]; then
    echo "⚠️  Passed with $WARNINGS warning(s)"
    echo "VERIFIED_URL=$PUBLISHED_URL"
else
    echo "❌ FAILED: $ERRORS error(s), $WARNINGS warning(s)"
    echo "UNVERIFIED_URL=$PUBLISHED_URL"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $ERRORS

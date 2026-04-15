#!/bin/bash
# common.sh - Common utilities for kf-cli
# Version: 0.1.0

set -e

# Get today's date in YYYY-MM-DD format
today() {
  date "+%Y-%m-%d"
}

# Generate slug from title (lowercase, hyphens, alphanumeric only)
slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g'
}

# Smart filename generation: YYYY-MM-DD-slug
generate_filename() {
  local date=$(today)
  local title="$1"
  local slug=$(slugify "$title")
  echo "${date}-${slug}"
}

# Log message with timestamp
log() {
  echo "[$(date '+%H:%M:%S')] $*" >&2
}

# Error message and exit
error() {
  echo "[ERROR] $*" >&2
  exit 1
}

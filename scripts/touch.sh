#!/usr/bin/env bash
# touch — update modified: to now. Never touches date:.
# Usage: touch <slug> [--content-dir <path>]
set -euo pipefail

: "${FRONTMATTER_AWK:=$(dirname "${BASH_SOURCE[0]}")/_frontmatter.awk}"

slug=""
content_dir="${BLOG_CONTENT_DIR:-./content}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --content-dir) content_dir="$2"; shift 2 ;;
        --)            shift ;;
        -h|--help)     echo "usage: touch <slug> [--content-dir <path>]"; exit 0 ;;
        -*)            echo "unknown flag: $1" >&2; exit 2 ;;
        *)
            if [[ -z "$slug" ]]; then slug="$1"; shift
            else echo "extra arg: $1" >&2; exit 2
            fi ;;
    esac
done

[[ -z "$slug" ]] && { echo "usage: touch <slug>" >&2; exit 2; }

file="$content_dir/blog/$slug.md"
[[ -f "$file" ]] || { echo "no post: $file" >&2; exit 1; }

now="$(date -Iseconds)"
tmp="$(mktemp)"
awk -v SETTERS="modified=$now" -f "$FRONTMATTER_AWK" "$file" > "$tmp"
mv "$tmp" "$file"
echo "touched: $file (modified=$now)"

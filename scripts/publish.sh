#!/usr/bin/env bash
# publish — flip draft to false and stamp date: + modified: to now, atomically.
# Errors (exit 4) if the post is already published, so callers can detect
# wasted invocations.
# Usage: publish <slug> [--content-dir <path>]
set -euo pipefail

: "${FRONTMATTER_AWK:=$(dirname "${BASH_SOURCE[0]}")/_frontmatter.awk}"

slug=""
content_dir="${BLOG_CONTENT_DIR:-./content}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --content-dir) content_dir="$2"; shift 2 ;;
        --)            shift ;;
        -h|--help)     echo "usage: publish <slug> [--content-dir <path>]"; exit 0 ;;
        -*)            echo "unknown flag: $1" >&2; exit 2 ;;
        *)
            if [[ -z "$slug" ]]; then slug="$1"; shift
            else echo "extra arg: $1" >&2; exit 2
            fi ;;
    esac
done

[[ -z "$slug" ]] && { echo "usage: publish <slug>" >&2; exit 2; }

file="$content_dir/blog/$slug.md"
[[ -f "$file" ]] || { echo "no post: $file" >&2; exit 1; }

current_draft="$(
    awk '
        NR == 1 && /^---$/ { in_fm = 1; next }
        in_fm && /^---$/   { exit }
        in_fm && match($0, "^draft[[:space:]]*:") {
            sub("^draft[[:space:]]*:[[:space:]]*", "")
            print
            exit
        }
    ' "$file"
)"

if [[ "$current_draft" == "false" ]]; then
    echo "already published: $file" >&2
    exit 4
fi

now="$(date -Iseconds)"
tmp="$(mktemp)"
awk -v SETTERS="draft=false;date=$now;modified=$now" -f "$FRONTMATTER_AWK" "$file" > "$tmp"
mv "$tmp" "$file"
echo "published: $file (date=$now, modified=$now)"

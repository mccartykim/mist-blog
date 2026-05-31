#!/usr/bin/env bash
# set-draft — flip the draft flag without touching dates.
# Usage: set-draft <slug> <true|false> [--content-dir <path>]
set -euo pipefail

: "${FRONTMATTER_AWK:=$(dirname "${BASH_SOURCE[0]}")/_frontmatter.awk}"

slug=""
value=""
content_dir="${BLOG_CONTENT_DIR:-./content}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --content-dir) content_dir="$2"; shift 2 ;;
        --)            shift ;;
        -h|--help)     echo "usage: set-draft <slug> <true|false> [--content-dir <path>]"; exit 0 ;;
        -*)            echo "unknown flag: $1" >&2; exit 2 ;;
        *)
            if [[ -z "$slug" ]]; then slug="$1"; shift
            elif [[ -z "$value" ]]; then value="$1"; shift
            else echo "extra arg: $1" >&2; exit 2
            fi ;;
    esac
done

[[ -z "$slug" || -z "$value" ]] && { echo "usage: set-draft <slug> <true|false>" >&2; exit 2; }
[[ "$value" == "true" || "$value" == "false" ]] || {
    echo "draft must be 'true' or 'false', got: $value" >&2; exit 2
}

file="$content_dir/blog/$slug.md"
[[ -f "$file" ]] || { echo "no post: $file" >&2; exit 1; }

tmp="$(mktemp)"
awk -v SETTERS="draft=$value" -f "$FRONTMATTER_AWK" "$file" > "$tmp"
mv "$tmp" "$file"
echo "set-draft: $file (draft=$value)"

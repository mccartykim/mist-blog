#!/usr/bin/env bash
# new — scaffold a new draft post.
# Usage: new <slug> [--title "..."] [--draft|--no-draft] [--date <iso8601>]
#               [--content-dir <path>]
# Defaults: draft: true, date: now, title: slug humanized.
set -euo pipefail

slug=""
title=""
draft="true"
date_val=""
content_dir="${BLOG_CONTENT_DIR:-./content}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --title)        title="$2"; shift 2 ;;
        --draft)        draft="true"; shift ;;
        --no-draft)     draft="false"; shift ;;
        --date)         date_val="$2"; shift 2 ;;
        --content-dir)  content_dir="$2"; shift 2 ;;
        --)             shift ;;
        -h|--help)
            cat <<'USAGE'
usage: new <slug> [--title "..."] [--draft|--no-draft] [--date <iso8601>]
                  [--content-dir <path>]
  Writes <content-dir>/blog/<slug>.md with frontmatter stamped.
  Exits 2 on usage error, 3 on slug collision.
USAGE
            exit 0 ;;
        -*) echo "unknown flag: $1" >&2; exit 2 ;;
        *)
            if [[ -z "$slug" ]]; then slug="$1"; shift
            else echo "extra arg: $1" >&2; exit 2
            fi ;;
    esac
done

[[ -z "$slug" ]] && { echo "usage: new <slug>" >&2; exit 2; }
[[ -z "$title" ]] && title="${slug//[_-]/ }"
[[ -z "$date_val" ]] && date_val="$(date -Iseconds)"

blog_dir="$content_dir/blog"
file="$blog_dir/$slug.md"
[[ -e "$file" ]] && { echo "slug collision: $file already exists" >&2; exit 3; }

mkdir -p "$blog_dir"
cat > "$file" <<EOF
---
date: $date_val
modified:
title: $title
draft: $draft
---

EOF

echo "created: $file"

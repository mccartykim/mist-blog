#!/usr/bin/env bash
# list — enumerate posts in a content tree.
# Usage: list [drafts|published|all] [--content-dir <path>] [--format table|slugs]
# No VCS, no network. Pure local read.
set -euo pipefail

content_dir="${BLOG_CONTENT_DIR:-./content}"
filter="all"
format="table"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --content-dir) content_dir="$2"; shift 2 ;;
        --format) format="$2"; shift 2 ;;
        drafts|published|all) filter="$1"; shift ;;
        -h|--help)
            cat <<'USAGE'
usage: list [drafts|published|all] [--content-dir <path>] [--format table|slugs]
  drafts     show only posts with draft: true
  published  show only posts with draft: false
  all        show everything (default)
  --format table   slug | date | draft | title (default)
  --format slugs   one slug per line, machine-friendly
USAGE
            exit 0 ;;
        *) echo "unexpected arg: $1" >&2; exit 2 ;;
    esac
done

blog_dir="$content_dir/blog"
[[ -d "$blog_dir" ]] || { echo "no blog dir at: $blog_dir" >&2; exit 1; }

fm_get() {
    # Print the value of a single frontmatter key (empty if absent).
    # Stops at the closing --- so it doesn't accidentally grep the body.
    local key="$1" file="$2"
    awk -v k="$key" '
        NR == 1 && /^---$/ { in_fm = 1; next }
        in_fm && /^---$/   { exit }
        in_fm && match($0, "^" k "[[:space:]]*:") {
            sub("^" k "[[:space:]]*:[[:space:]]*", "")
            print
            exit
        }
    ' "$file"
}

if [[ "$format" == "table" ]]; then
    printf "%-32s %-26s %-5s %s\n" "SLUG" "DATE" "DRAFT" "TITLE"
fi

shopt -s nullglob
for file in "$blog_dir"/*.md; do
    base="$(basename "$file")"
    [[ "$base" == "_index.md" ]] && continue

    slug="${base%.md}"
    title="$(fm_get title "$file")"
    date="$(fm_get date "$file")"
    draft="$(fm_get draft "$file")"
    draft="${draft:-false}"

    case "$filter" in
        drafts)    [[ "$draft" == "true"  ]] || continue ;;
        published) [[ "$draft" == "false" ]] || continue ;;
    esac

    case "$format" in
        slugs) printf '%s\n' "$slug" ;;
        table) printf "%-32s %-26s %-5s %s\n" "$slug" "${date:0:26}" "$draft" "$title" ;;
        *) echo "unknown format: $format" >&2; exit 2 ;;
    esac
done

#!/usr/bin/env bash
# preview — spin up the mist_blog engine locally pointed at this content dir.
# Usage: preview <slug> [--port <int>] [--content-dir <path>]
# Does not auto-open a browser; just prints the URL and waits for Ctrl-C.
set -euo pipefail

slug=""
port="${PORT:-8765}"
host="${HOST:-127.0.0.1}"
content_dir="${BLOG_CONTENT_DIR:-./content}"
title=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --port)        port="$2"; shift 2 ;;
        --content-dir) content_dir="$2"; shift 2 ;;
        --host)        host="$2"; shift 2 ;;
        --title)       title="$2"; shift 2 ;;
        --)            shift ;;
        -h|--help)
            cat <<'USAGE'
usage: preview <slug> [--port <int>] [--host <addr>] [--content-dir <path>]
                      [--title <string>]
  Starts mist_blog with BLOG_CONTENT_DIR pointed at <content-dir> and
  prints the URL for the post. Ctrl-C cleans up the child server.
  --title overrides BLOG_TITLE for this preview only. All other BLOG_*
  identity vars (AUTHOR, DESCRIPTION, COPYRIGHT, etc.) are inherited
  from the parent shell — set them in your .envrc if direnv-using, or
  export them in your shell rc.
USAGE
            exit 0 ;;
        -*) echo "unknown flag: $1" >&2; exit 2 ;;
        *)
            if [[ -z "$slug" ]]; then slug="$1"; shift
            else echo "extra arg: $1" >&2; exit 2
            fi ;;
    esac
done

[[ -z "$slug" ]] && { echo "usage: preview <slug> [--port N]" >&2; exit 2; }

file="$content_dir/blog/$slug.md"
[[ -f "$file" ]] || echo "warn: no post at $file (you can still navigate the index)" >&2

content_dir_abs="$(realpath "$content_dir")"
export BLOG_CONTENT_DIR="$content_dir_abs"
export PORT="$port"
export HOST="$host"
[[ -n "$title" ]] && export BLOG_TITLE="$title"

mist_blog &
pid=$!
trap 'kill "$pid" 2>/dev/null || true' EXIT INT TERM

# Poll readiness rather than blind-sleeping
ready=0
for _ in $(seq 1 30); do
    if curl -sS --fail --max-time 1 "http://${host}:${port}/" -o /dev/null 2>/dev/null; then
        ready=1; break
    fi
    sleep 0.2
done

if (( ready == 0 )); then
    echo "server did not become ready on http://${host}:${port}/" >&2
    exit 1
fi

echo
echo "  Preview ready: http://${host}:${port}/blog/${slug}"
echo "  Blog index:    http://${host}:${port}/blog"
echo "  Press Ctrl-C to stop."
echo

wait "$pid"

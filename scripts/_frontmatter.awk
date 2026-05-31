# _frontmatter.awk — safe in-place edits to YAML frontmatter.
#
# Reads a markdown file with a `--- ... ---` frontmatter block at the very
# top. For each key=value pair in the SETTERS variable (semicolon-separated),
# either replaces that key's value if it exists, or inserts the key just
# before the closing `---` if it doesn't. All other lines pass through
# verbatim, including the body.
#
# Usage:
#   awk -v SETTERS="draft=false;date=2026-05-30T19:00:00-04:00" \
#       -f _frontmatter.awk in.md > out.md
#
# Caveats:
#   - SETTERS values must not contain `;` (we use it as the separator).
#     For our use cases (booleans, ISO 8601 dates) this is fine.
#   - The frontmatter must start with `---` on line 1 (matching the engine's
#     parser at src/app/content.gleam:32). Files without frontmatter pass
#     through unchanged.

BEGIN {
    n = split(SETTERS, pairs, ";")
    for (i = 1; i <= n; i++) {
        eq = index(pairs[i], "=")
        if (eq > 0) {
            key = substr(pairs[i], 1, eq - 1)
            val = substr(pairs[i], eq + 1)
            new_val[key] = val
            seen[key] = 0
            ordered[i] = key
        }
    }
    state = "pre"
}

# Opening --- on line 1 enters frontmatter
NR == 1 && /^---$/ {
    state = "in_fm"
    print
    next
}

# Closing --- exits frontmatter; before printing it, emit any unseen setters
state == "in_fm" && /^---$/ {
    for (i = 1; i <= n; i++) {
        k = ordered[i]
        if (k != "" && !seen[k]) {
            print k ": " new_val[k]
            seen[k] = 1
        }
    }
    state = "body"
    print
    next
}

# Inside frontmatter: replace matching key, else pass through
state == "in_fm" {
    matched = 0
    for (i = 1; i <= n; i++) {
        k = ordered[i]
        if (k != "" && !seen[k] && match($0, "^" k "[[:space:]]*:")) {
            print k ": " new_val[k]
            seen[k] = 1
            matched = 1
            break
        }
    }
    if (!matched) print
    next
}

# Everything else (pre-frontmatter, body) passes through
{ print }

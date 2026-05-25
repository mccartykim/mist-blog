import jot

// Regression suite for jot Djot rendering (mb-1py, updated for v11 in mb-d9o).
// Originally pinned the broken v5.0.1 output for seven spec gaps. After the
// v5 → v11 bump (mb-d9o), five of those gaps closed upstream — those
// assertions now pin the CORRECT output and will fail again if jot regresses.
// The remaining gaps (tables, definition lists, compact nested lists without a
// blank line) continue to pin the current broken output.

pub fn nested_2space_test() {
  // Compact nested list (no blank line between parent and child).
  // jot v11 STILL flattens this — the inner "* B" is kept as literal text.
  // Likely a Djot spec choice rather than a bug. Tracked as a remaining gap.
  let expected = "<ul>\n<li>\nA\n* B\n</li>\n</ul>\n"
  assert jot.to_html("* A\n  * B") == expected
}

pub fn nested_4space_test() {
  // Same as above with 4-space indent — still flattens in v11.
  let expected = "<ul>\n<li>\nA\n* B\n</li>\n</ul>\n"
  assert jot.to_html("* A\n    * B") == expected
}

pub fn nested_blankline_2space_test() {
  // Was broken in v5 (rendered as two sibling lists). Fixed in jot v9 per
  // mb-85y: now produces a properly nested <ul> inside the parent <li>.
  let expected = "<ul>\n<li>\nA\n<ul>\n<li>\nB\n</li>\n</ul>\n</li>\n</ul>\n"
  assert jot.to_html("* A\n\n  * B") == expected
}

pub fn ordered_list_test() {
  // Was broken in v5 (literal paragraph). Fixed in jot v9 per mb-85y:
  // now produces a proper <ol>.
  let expected =
    "<ol>\n<li>\nfirst\n</li>\n<li>\nsecond\n</li>\n<li>\nthird\n</li>\n</ol>\n"
  assert jot.to_html("1. first\n2. second\n3. third") == expected
}

pub fn block_quote_test() {
  // Was broken in v5 (escaped paragraph). Fixed in jot v6 per mb-85y:
  // now produces a proper <blockquote>.
  let expected =
    "<blockquote>\n<p>quoted line one\nquoted line two</p>\n</blockquote>\n"
  assert jot.to_html("> quoted line one\n> quoted line two") == expected
}

pub fn table_unsupported_test() {
  // STILL unsupported in jot v11 (upstream jot#36). The pipe-table syntax
  // renders as a literal paragraph, with smartypants now collapsing
  // "---" into an em-dash (—). Pinning the new broken output so a future
  // upstream fix trips this test.
  let expected = "<p>| a | b |\n|—|—|\n| 1 | 2 |</p>\n"
  assert jot.to_html("| a | b |\n|---|---|\n| 1 | 2 |") == expected
}

pub fn div_block_test() {
  // Was broken in v5 (literal paragraph). Fixed in jot v7 per mb-85y:
  // now produces a real <div> with the class attribute.
  let expected = "<div class=\"warning\">\n<p>This is a warning.</p>\n</div>\n"
  assert jot.to_html("::: warning\nThis is a warning.\n:::") == expected
}

pub fn definition_list_unsupported_test() {
  // STILL unsupported in jot v11 — renders as a literal paragraph.
  let expected = "<p>: term\ndefinition</p>\n"
  assert jot.to_html(": term\n  definition") == expected
}

pub fn span_attr_test() {
  // Was broken in v5 (literal text). Fixed in jot v8/v9 per mb-85y:
  // now produces a proper <span> with the class attribute.
  let expected = "<p>Hello <span class=\"greet\">world</span>!</p>\n"
  assert jot.to_html("Hello [world]{.greet}!") == expected
}

pub fn footnote_supported_test() {
  // Sanity: footnotes DO work per spec.
  let out = jot.to_html("Here.[^x]\n\n[^x]: A note.")
  assert out
    == "<p>Here.<a id=\"fnref1\" href=\"#fn1\" role=\"doc-noteref\"><sup>1</sup></a></p>\n<section role=\"doc-endnotes\">\n<hr>\n<ol>\n<li id=\"fn1\">\n<p>A note.<a href=\"#fnref1\" role=\"doc-backlink\">↩︎</a></p>\n</li>\n</ol>\n</section>\n"
}

pub fn hard_break_supported_test() {
  // Sanity: hard breaks (backslash + newline) DO work per spec.
  assert jot.to_html("line one\\\nline two")
    == "<p>line one<br>\nline two</p>\n"
}

// Smoke test for the user-facing bug (mb-d9o): the kimb-blog-content homepage
// originally used a nested bullet list that v5 flattened, forcing a workaround
// commit (kbc 039f70d). Confirm v11 renders the standard Djot nested-list form
// as a real nested <ul> so the workaround can be reverted.
pub fn smoke_nested_list_user_content_test() {
  let input =
    "* Projects\n\n  * Mist Blog\n  * Gas Town\n\n* Notes\n\n  * Djot vs Markdown"
  let html = jot.to_html(input)
  // Outer list contains two items, each with a nested <ul>.
  assert html
    == "<ul>\n<li>\nProjects\n<ul>\n<li>\nMist Blog\n</li>\n<li>\nGas Town\n</li>\n</ul>\n</li>\n<li>\nNotes\n<ul>\n<li>\nDjot vs Markdown\n</li>\n</ul>\n</li>\n</ul>\n"
}

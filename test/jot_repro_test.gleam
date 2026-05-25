import jot

// Regression suite documenting Djot spec gaps in jot v5.0.1 (mb-1py).
// Each assertion captures the CURRENT (non-spec-conformant) output. When jot is
// upgraded and a feature gains spec support, the matching test will fail —
// signalling that the surrounding workaround can be removed.

pub fn nested_2space_test() {
  // Spec: this should produce a nested <ul> inside the outer <li>.
  // jot v5.0.1: the inner "* B" is kept as literal paragraph text.
  let expected = "<ul>\n<li>\nA\n* B\n</li>\n</ul>\n"
  assert jot.to_html("* A\n  * B") == expected
}

pub fn nested_4space_test() {
  let expected = "<ul>\n<li>\nA\n* B\n</li>\n</ul>\n"
  assert jot.to_html("* A\n    * B") == expected
}

pub fn nested_blankline_2space_test() {
  // Renders as two SIBLING top-level lists, not nested.
  let expected = "<ul>\n<li>\nA\n</li>\n</ul>\n<ul>\n<li>\nB\n</li>\n</ul>\n"
  assert jot.to_html("* A\n\n  * B") == expected
}

pub fn ordered_list_unsupported_test() {
  // Spec: ordered lists with "1." style. jot v5.0.1: literal paragraph.
  let expected = "<p>1. first\n2. second\n3. third</p>\n"
  assert jot.to_html("1. first\n2. second\n3. third") == expected
}

pub fn block_quote_unsupported_test() {
  // Spec: "> " produces <blockquote>. jot v5.0.1: literal paragraph (escaped).
  let expected = "<p>&gt; quoted line one\n&gt; quoted line two</p>\n"
  assert jot.to_html("> quoted line one\n> quoted line two") == expected
}

pub fn table_unsupported_test() {
  let expected = "<p>| a | b |\n|---|---|\n| 1 | 2 |</p>\n"
  assert jot.to_html("| a | b |\n|---|---|\n| 1 | 2 |") == expected
}

pub fn div_block_unsupported_test() {
  let expected = "<p>::: warning\nThis is a warning.\n:::</p>\n"
  assert jot.to_html("::: warning\nThis is a warning.\n:::") == expected
}

pub fn definition_list_unsupported_test() {
  let expected = "<p>: term\ndefinition</p>\n"
  assert jot.to_html(": term\n  definition") == expected
}

pub fn span_attr_unsupported_test() {
  // Spec: inline span with attached attributes. jot v5.0.1: literal text.
  let expected = "<p>Hello [world]{.greet}!</p>\n"
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

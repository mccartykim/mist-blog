import app/renderer
import gleam/string
import jot

fn render(djot: String, base: String) -> String {
  djot
  |> renderer.preprocess_wikilinks(base)
  |> jot.to_html
}

pub fn simple_wikilink_test() {
  let html = render("[[foo]]", "/blog/")
  assert string.contains(html, "<a href=\"/blog/foo\">foo</a>")
}

pub fn aliased_wikilink_test() {
  let html = render("[[foo|Bar baz]]", "/blog/")
  assert string.contains(html, "<a href=\"/blog/foo\">Bar baz</a>")
}

pub fn slug_with_hyphens_and_underscores_test() {
  let html = render("[[foo-bar_baz]]", "/blog/")
  assert string.contains(html, "<a href=\"/blog/foo-bar_baz\">foo-bar_baz</a>")
}

pub fn slug_with_digits_test() {
  let html = render("[[post-2024-01]]", "/blog/")
  assert string.contains(
    html,
    "<a href=\"/blog/post-2024-01\">post-2024-01</a>",
  )
}

pub fn wikilink_in_fenced_code_block_is_literal_test() {
  let djot = "```\n[[foo]]\n```"
  let out = renderer.preprocess_wikilinks(djot, "/blog/")
  // Wikilink inside fenced block stays literal — no transformation.
  assert string.contains(out, "[[foo]]")
  assert !string.contains(out, "/blog/foo")
}

pub fn wikilink_in_inline_code_is_literal_test() {
  let djot = "Some text with `[[foo]]` in code."
  let out = renderer.preprocess_wikilinks(djot, "/blog/")
  assert string.contains(out, "`[[foo]]`")
  assert !string.contains(out, "/blog/foo")
}

pub fn empty_alias_is_left_literal_test() {
  // `[[slug|]]` is malformed (no alias text); leave as-is rather than
  // guessing intent. Per bead design choice.
  let out = renderer.preprocess_wikilinks("[[slug|]]", "/blog/")
  assert out == "[[slug|]]"
}

pub fn standard_reference_link_untouched_test() {
  // Single-bracket `[foo]` is a Djot reference link — do not transform it.
  let djot = "See [foo] for details."
  let out = renderer.preprocess_wikilinks(djot, "/blog/")
  assert out == djot
}

pub fn custom_base_path_test() {
  let html = render("[[foo]]", "/wiki/")
  assert string.contains(html, "<a href=\"/wiki/foo\">foo</a>")
}

pub fn aliased_with_special_chars_test() {
  let html = render("[[foo|Bar & baz!]]", "/blog/")
  assert string.contains(html, "href=\"/blog/foo\"")
  assert string.contains(html, "Bar &amp; baz!</a>")
}

pub fn mixed_text_and_wikilinks_test() {
  let html =
    render("Read about [[foo|the foo post]] and [[bar]] for context.", "/blog/")
  assert string.contains(html, "<a href=\"/blog/foo\">the foo post</a>")
  assert string.contains(html, "<a href=\"/blog/bar\">bar</a>")
}

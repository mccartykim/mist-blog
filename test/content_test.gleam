import app/content
import envoy
import gleam/string

// The engine's own priv/content/blog is gitignored personal content, so these
// tests point BLOG_CONTENT_DIR at committed fixtures with one published post
// and one draft — mirroring how the NixOS module injects the content dir.

pub fn get_post_by_slug_draft_handling_test() {
  envoy.set("BLOG_CONTENT_DIR", "test/fixtures/content")

  // A published post is still served, content intact (raw markdown with
  // frontmatter, exactly what the old file-read path returned).
  let assert Ok(post) = content.get_post_by_slug("published-post")
  assert string.contains(post, "Published body.")

  // A draft post is NOT reachable at its direct URL.
  let assert Error(Nil) = content.get_post_by_slug("draft-post")

  // An unknown slug still errors (router renders 404), as before.
  let assert Error(Nil) = content.get_post_by_slug("no-such-slug")

  envoy.unset("BLOG_CONTENT_DIR")
}

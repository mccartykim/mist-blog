import gleam/string_tree
import jot

pub fn render_html(djot: String) -> string_tree.StringTree {
  // TODO: isolate frontmatter between --- lines
  let head =
    "<head><title>Mist Blog</title><link rel=\"stylesheet\" href=\"assets/style.css\"></head>"
  // TODO navigation bars
  let body = jot.to_html(djot)
  // TODO footer

  string_tree.from_strings([head, body])
}

pub fn render_index_page() -> string_tree.StringTree {
  // TODO: isolate frontmatter between --- lines
  let head =
    "<head><title>Mist Blog</title><link rel=\"stylesheet\" href=\"assets/style.css\"></head>"
  // TODO navigation bars
  // TODO iterate over blog posts
  let body = "<h1>Welcome to Mist Blog</h1><p>This is the index page.</p>"
  // TODO footer

  string_tree.from_strings([head, body])
}

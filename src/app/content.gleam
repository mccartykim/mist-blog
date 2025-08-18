import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string
import simplifile
import wisp

// --- Data Structures ---

pub type Post {
  Post(
    title: String,
    date: String,
    // Using String for now, can be parsed into a proper date type later
    tags: List(String),
    draft: Bool,
    path: String,
    // The original file path
    url: String,
    // The URL slug, e.g. /blog/hello-world
    content: String,
    raw_content: String,
    // The full markdown content with frontmatter
  )
}

// --- Frontmatter Parsing ---

/// This is a simplified YAML parser for the frontmatter.
/// It handles key: value pairs and simple tag lists.
fn parse_frontmatter(
  lines: List(String),
) -> Result(#(Dict(String, String), List(String)), simplifile.FileError) {
  let metadata_lines = list.take_while(lines, fn(line) { line != "---" })

  let content_lines = case list.drop_while(lines, fn(line) { line != "---" }) {
    [] -> []
    [_first, ..rest] -> rest
  }

  let metadata =
    metadata_lines
    |> list.fold(dict.new(), fn(acc, line) {
      case string.split_once(line, on: ":") {
        Ok(#(key, value)) -> {
          let key = string.trim(key)
          let value = string.trim(value)
          dict.insert(acc, key, value)
        }
        Error(_) -> acc
        // Ignore lines without a colon
      }
    })

  Ok(#(metadata, content_lines))
}

/// Takes the full content of a markdown file and its path, and returns a Post.
fn extract_post_from_markdown(
  markdown: String,
  path: String,
) -> Result(Post, simplifile.FileError) {
  use #(metadata, content_lines) <- result.try(
    markdown
    |> string.crop("---")
    |> string.split(on: "\n")
    |> list.drop(1)
    |> parse_frontmatter,
  )

  let title = dict.get(metadata, "title") |> result.unwrap("")
  let date = dict.get(metadata, "date") |> result.unwrap("")
  let draft =
    dict.get(metadata, "draft")
    |> result.map(string.lowercase)
    |> result.map(fn(s) { s == "true" })
    |> result.unwrap(False)

  let tags =
    dict.get(metadata, "tags")
    |> result.map(fn(tag_string) {
      tag_string
      |> string.split(on: ",")
      |> list.map(string.trim)
    })
    |> result.unwrap([])

  let content = string.join(content_lines, with: "\n")

  // Generate URL from filename
  let slug =
    path
    |> string.split(on: "/")
    |> list.last
    |> result.unwrap(or: path)
    |> string.replace(each: ".md", with: "")

  Ok(Post(
    title: title,
    date: date,
    tags: tags,
    draft: draft,
    path: path,
    url: "/blog/" <> slug,
    content: content,
    raw_content: markdown,
  ))
}

// --- Post Loading and Processing ---

/// Reads all .md files from the blog content directory and parses them into Posts.
pub fn get_all_posts() -> List(Post) {
  let assert Ok(priv_dir) = wisp.priv_directory("mist_blog")
  let blog_dir = priv_dir <> "/content/blog/"
  let assert Ok(files) = simplifile.read_directory(blog_dir)

  files
  |> list.filter(fn(file) { string.ends_with(file, ".md") })
  |> list.filter(fn(file) { file != "_index.md" })
  |> list.try_map(fn(filename) {
    let path = blog_dir <> filename
    use markdown <- result.try(simplifile.read(path))
    extract_post_from_markdown(markdown, path)
  })
  |> result.unwrap([])
}

/// Returns all posts that are not marked as draft.
pub fn get_published_posts() -> List(Post) {
  get_all_posts()
  |> list.filter(fn(post) { !post.draft })
}

/// Sorts posts with the newest first.
/// This is a string comparison, which works for ISO 8601 dates (YYYY-MM-DD).
pub fn sort_posts(posts: List(Post)) -> List(Post) {
  list.sort(posts, fn(a, b) { string.compare(b.date, a.date) })
}

// --- Tag Aggregation ---

/// Extracts a unique, sorted list of all tags from a list of posts.
pub fn get_all_tags(posts: List(Post)) -> List(String) {
  posts
  |> list.flat_map(fn(post) { post.tags })
  |> list.unique
  |> list.sort(string.compare)
}

/// Groups posts by tag.
pub fn get_posts_by_tag(posts: List(Post)) -> Dict(String, List(Post)) {
  let all_tags = get_all_tags(posts)

  all_tags
  |> list.fold(dict.new(), fn(acc, tag) {
    let tagged_posts =
      posts
      |> list.filter(fn(post) { list.contains(post.tags, tag) })

    dict.insert(acc, tag, tagged_posts)
  })
}

// --- Single File Loading ---

/// Load the homepage content
pub fn get_homepage() -> String {
  let assert Ok(priv_dir) = wisp.priv_directory("mist_blog")
  let assert Ok(content) = simplifile.read(priv_dir <> "/content/_index.md")
  content
}

/// Load a single post by slug
pub fn get_post_by_slug(slug: String) -> Result(String, simplifile.FileError) {
  let assert Ok(priv_dir) = wisp.priv_directory("mist_blog")
  simplifile.read(priv_dir <> "/content/blog/" <> slug <> ".md")
}

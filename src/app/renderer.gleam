import app/content.{type Post}
import app/web.{type Context}

import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/regexp
import gleam/string
import gleam/string_tree
import jot
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import webls/rss.{RssChannel, RssItem}

pub fn render_html(djot: String, ctx: Context) -> string_tree.StringTree {
  let maybe_frontmatter_and_content: Result(#(String, String), Nil) =
    djot
    |> string.drop_start(3)
    |> string.split_once(on: "---")

  let fm_and_content = case maybe_frontmatter_and_content {
    Ok(frontmatter_and_content) -> {
      frontmatter_and_content
    }
    _ -> pair.new("", djot)
  }

  let head =
    html.head([], [
      html.title([], ctx.configuration.title),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/assets/style.css"),
      ]),
      html.meta([attribute.charset("utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),
      html.meta([
        attribute.name("description"),
        attribute.content(ctx.configuration.description),
      ]),
      // todo opengraph, twitter
      html.link([
        attribute.rel("alternate"),
        attribute.enctype("application/rss+xml"),
        attribute.title(ctx.configuration.title <> "RSS Feed"),
        attribute.href("/rss.xml"),
      ]),
    ])
    |> element.to_string

  let body =
    html.body([], [
      html.a([attribute.href("/"), attribute.class("title")], [
        html.h1([], [html.text(ctx.configuration.title)]),
      ]),
      html.nav([], [
        html.a([attribute.href("/")], [element.text("Home")]),
        html.a([attribute.href("/blog")], [element.text("Blog")]),
        html.a([attribute.href("/tags")], [element.text("Tags")]),
      ]),
      html.div([], [
        element.unsafe_raw_html(
          "",
          "div",
          [],
          fm_and_content
            |> pair.second
            |> preprocess_wikilinks(ctx.configuration.wikilink_base)
            |> jot.to_html,
        ),
      ]),
      html.footer([], [
        html.small([], [
          element.text(
            ctx.configuration.copyright <> " | " <> ctx.configuration.generator,
          ),
        ]),
      ]),
    ])
    |> element.to_string

  string_tree.from_strings([head, body])
}

pub fn render_blog_index(
  posts: List(Post),
  ctx: Context,
) -> string_tree.StringTree {
  let content_html =
    html.div([], [
      html.h2([], [element.text("Blog Posts")]),
      html.div(
        [attribute.class("post-list")],
        list.map(posts, render_post_summary),
      ),
    ])
    |> element.to_string

  render_page_with_content(content_html, ctx)
}

pub fn render_tags_index(
  tags: List(String),
  ctx: Context,
) -> string_tree.StringTree {
  let content_html =
    html.div([], [
      html.h2([], [element.text("Tags")]),
      html.div(
        [attribute.class("tag-list")],
        list.map(tags, fn(tag) {
          html.a([attribute.href("/tags/" <> tag), attribute.class("tag")], [
            element.text(tag),
          ])
        }),
      ),
    ])
    |> element.to_string

  render_page_with_content(content_html, ctx)
}

pub fn render_tag_page(
  tag: String,
  posts: List(Post),
  ctx: Context,
) -> string_tree.StringTree {
  let content_html =
    html.div([], [
      html.h2([attribute.class("tag-page-title")], [
        element.text("Posts tagged with \"" <> tag <> "\""),
      ]),
      html.div(
        [attribute.class("post-list")],
        list.map(posts, render_post_summary),
      ),
    ])
    |> element.to_string

  render_page_with_content(content_html, ctx)
}

fn render_post_summary(post: Post) -> Element(msg) {
  html.article([attribute.class("post-summary")], [
    html.time(
      [attribute.attribute("datetime", post.date), attribute.class("post-date")],
      [element.text(post.date)],
    ),
    html.h3([attribute.class("post-title")], [
      html.a([attribute.href(post.url)], [element.text(post.title)]),
    ]),
    html.div(
      [attribute.class("tags")],
      list.map(post.tags, fn(tag) {
        html.a([attribute.href("/tags/" <> tag), attribute.class("tag")], [
          element.text(tag),
        ])
      }),
    ),
  ])
}

fn render_page_with_content(
  content_html: String,
  ctx: Context,
) -> string_tree.StringTree {
  let head =
    html.head([], [
      html.title([], ctx.configuration.title),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/assets/style.css"),
      ]),
      html.meta([attribute.charset("utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),
      html.meta([
        attribute.name("description"),
        attribute.content(ctx.configuration.description),
      ]),
      html.link([
        attribute.rel("alternate"),
        attribute.enctype("application/rss+xml"),
        attribute.title(ctx.configuration.title <> "RSS Feed"),
        attribute.href("/rss.xml"),
      ]),
    ])
    |> element.to_string

  let body =
    html.body([], [
      html.a([attribute.href("/"), attribute.class("title")], [
        html.h1([], [html.text(ctx.configuration.title)]),
      ]),
      html.nav([], [
        html.a([attribute.href("/")], [element.text("Home")]),
        html.a([attribute.href("/blog")], [element.text("Blog")]),
        html.a([attribute.href("/tags")], [element.text("Tags")]),
      ]),
      element.unsafe_raw_html("", "div", [], content_html),
      html.footer([], [
        html.small([], [
          element.text(
            ctx.configuration.copyright <> " | " <> ctx.configuration.generator,
          ),
        ]),
      ]),
    ])
    |> element.to_string

  string_tree.from_strings([head, body])
}

pub fn render_rss_feed(posts: List(Post), ctx: Context) -> String {
  let base_url = ctx.configuration.base_url

  // TODO:
  // - consider reading base_url from env var (BLOG_BASE_URL) so config changes don't require recompilation
  // - pub_date on RSS items could use birl for proper RFC 2822 formatting from post.date
  // - RSS items currently include draft posts; filter with content.get_published_posts if that matters at the call site
  // - content.extract_excerpt takes the first 3 raw lines; could instead render markdown first, then truncate HTML safely

  let rss_items =
    list.map(posts, fn(post) {
      RssItem(
        title: post.title,
        link: Some(base_url <> post.url),
        description: extract_excerpt(post.content),
        pub_date: None,
        author: Some(ctx.configuration.email),
        guid: Some(#(base_url <> post.url, Some(True))),
        categories: [],
        comments: None,
        enclosure: None,
        source: None,
      )
    })

  let channel =
    RssChannel(
      title: ctx.configuration.title,
      description: ctx.configuration.description,
      link: base_url,
      items: rss_items,
      categories: [],
      cloud: None,
      copyright: Some(ctx.configuration.copyright),
      docs: None,
      generator: Some(ctx.configuration.generator),
      image: None,
      language: Some(ctx.configuration.language),
      last_build_date: None,
      managing_editor: Some(ctx.configuration.email),
      pub_date: None,
      skip_days: [],
      skip_hours: [],
      text_input: None,
      ttl: None,
      web_master: Some(ctx.configuration.email),
    )

  [channel]
  |> rss.to_string()
}

fn extract_excerpt(content: String) -> String {
  content
  |> string.split(on: "\n")
  |> list.take(3)
  |> string.join(with: " ")
  |> string.trim()
}

/// Rewrite Obsidian-style wikilinks to standard Djot inline links before
/// handing the source to `jot.to_html`. Fenced code blocks (```...```) and
/// inline code spans (`...`) are left untouched.
///
///   [[slug]]              -> [slug](BASE + slug)
///   [[slug|display text]] -> [display text](BASE + slug)
pub fn preprocess_wikilinks(djot: String, base: String) -> String {
  let assert Ok(re) =
    regexp.from_string(
      "(?s:```.*?```)|`[^`\n]*`|\\[\\[([a-z0-9_\\-]+)(?:\\|([^\\]]+))?\\]\\]",
    )
  regexp.match_map(re, djot, fn(m) {
    // Submatch list length varies by which alternation branch matched:
    // wikilinks return one or two Some entries; code spans return none.
    case m.submatches {
      [Some(slug), Some(alias), ..] ->
        "[" <> alias <> "](" <> base <> slug <> ")"
      [Some(slug), ..] -> "[" <> slug <> "](" <> base <> slug <> ")"
      _ -> m.content
    }
  })
}

import app/web.{type Context}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option
import gleam/pair
import gleam/string
import gleam/string_tree
import jot
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn render_html(djot: String, ctx: Context) -> string_tree.StringTree {
  // TODO: isolate frontmatter between --- lines
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
      element.unsafe_raw_html(
        "",
        "div",
        [],
        jot.to_html(pair.second(fm_and_content)),
      ),
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

/// Convert djot markdown content to lustre elements
pub fn djot_to_lustre(djot_content: String) -> List(Element(msg)) {
  let content = jot.parse(djot_content).content

  content
  |> list.map(node_to_lustre(_, dict.new()))
}

/// Convert djot markdown content to lustre elements with reference links
pub fn djot_to_lustre_with_references(
  djot_content: String,
  references: Dict(String, String),
) -> List(Element(msg)) {
  jot.parse(djot_content).content
  |> list.map(node_to_lustre(_, references))
}

/// Convert a single jot node to a lustre element
fn node_to_lustre(
  node: jot.Container,
  references: Dict(String, String),
) -> Element(msg) {
  case node {
    // Block elements
    jot.Heading(attrs, level, content) -> {
      let lustre_attrs = attributes_to_lustre(attrs)
      let lustre_content = list.map(content, inlines_to_lustre(_, references))

      case level {
        1 -> html.h1(lustre_attrs, lustre_content)
        2 -> html.h2(lustre_attrs, lustre_content)
        3 -> html.h3(lustre_attrs, lustre_content)
        4 -> html.h4(lustre_attrs, lustre_content)
        5 -> html.h5(lustre_attrs, lustre_content)
        6 -> html.h6(lustre_attrs, lustre_content)
        _ ->
          html.div(
            [attribute.class("heading-level-" <> int.to_string(level))],
            lustre_content,
          )
      }
    }

    jot.Paragraph(attrs, content) -> {
      let lustre_attrs = attributes_to_lustre(attrs)
      let lustre_content = list.map(content, inlines_to_lustre(_, references))
      html.p(lustre_attrs, lustre_content)
    }

    jot.Codeblock(attrs, language, code) -> {
      let lustre_attrs = attributes_to_lustre(attrs)
      let lang_attr = case language {
        option.Some(lang) -> [attribute.attribute("data-lang", lang)]
        option.None -> []
      }
      html.pre(lustre_attrs, [html.code(lang_attr, [element.text(code)])])
    }

    jot.BulletList(layout, style, items) -> {
      let lustre_items =
        list.map(items, fn(item) {
          html.li([], [element.text(style)])
          html.li([], list.map(item, node_to_lustre(_, references)))
        })
      html.ul([], lustre_items)
    }

    jot.ThematicBreak -> {
      html.hr([])
    }

    jot.RawBlock(content) -> {
      let lustre_attrs = []
      html.pre(lustre_attrs, [element.text(content)])
    }
    // Special cases for any nodes I might have missed
    _ -> {
      // Fallback for unknown node types - render as div with debug info
      html.div(
        [
          attribute.class("unknown-djot-node"),
          attribute.attribute("data-node-type", "unknown"),
        ],
        [element.text("Unknown djot node")],
      )
    }
  }
}

fn inlines_to_lustre(
  node: jot.Inline,
  references: Dict(String, String),
) -> Element(msg) {
  case node {
    jot.Linebreak -> html.br([])
    jot.NonBreakingSpace -> html.span([], [element.text(" ")])
    jot.Text(msg) -> html.span([], [element.text(msg)])
    jot.Link(content, destination) -> {
      case destination {
        jot.Reference(path) ->
          html.a(
            [attribute.href(path)],
            list.map(content, inlines_to_lustre(_, references)),
          )
        jot.Url(url) ->
          html.a(
            [attribute.href(url)],
            list.map(content, inlines_to_lustre(_, references)),
          )
      }
    }
    // TODO does alt text work in image?
    jot.Image(content, destination) -> {
      case destination {
        jot.Reference(path) -> todo
        jot.Url(url) -> html.img([attribute.src(url)])
      }
    }
    jot.Emphasis(content) ->
      html.em([], list.map(content, inlines_to_lustre(_, references)))
    jot.Strong(content) ->
      html.strong([], list.map(content, inlines_to_lustre(_, references)))
    jot.Footnote(content) -> element.none()
    jot.Code(content) -> html.code([], [html.text(content)])
    jot.MathInline(content) -> html.math([], [html.text(content)])
    jot.MathDisplay(content) -> html.math([], [html.text(content)])
  }
}

/// Convert djot attributes to lustre attributes
fn attributes_to_lustre(
  attrs: Dict(String, String),
) -> List(attribute.Attribute(msg)) {
  use acc, key, value <- dict.fold(attrs, [])

  case key {
    "class" -> [attribute.class(value), ..acc]
    "id" -> [attribute.id(value), ..acc]
    _ -> [attribute.attribute(key, value), ..acc]
  }
}

/// Helper function to strip frontmatter from markdown before processing
pub fn strip_frontmatter(content: String) -> String {
  case string.starts_with(content, "---") {
    False -> content
    True -> {
      case string.split_once(content, "---") {
        Ok(#(_frontmatter, rest)) -> rest
        Error(_) -> content
        // No closing ---, return original
      }
    }
  }
}

/// Complete pipeline: strip frontmatter and convert to lustre
pub fn markdown_to_lustre(markdown_content: String) -> List(Element(msg)) {
  markdown_content
  |> strip_frontmatter
  |> djot_to_lustre
}

/// Complete pipeline with custom reference links
pub fn markdown_to_lustre_with_references(
  markdown_content: String,
  references: Dict(String, String),
) -> List(Element(msg)) {
  markdown_content
  |> strip_frontmatter
  |> djot_to_lustre_with_references(references)
}

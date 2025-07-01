import app/content
import app/renderer
import app/web.{type Context}
import gleam/dict
import gleam/string_tree

import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> {
      let markdown = content.get_homepage()
      renderer.render_html(markdown, ctx)
      |> wisp.html_response(200)
    }
    ["blog"] -> {
      let posts = content.get_published_posts() |> content.sort_posts()
      renderer.render_blog_index(posts, ctx)
      |> wisp.html_response(200)
    }
    ["blog", post] -> {
      case content.get_post_by_slug(post) {
        Ok(markdown) -> {
          renderer.render_html(markdown, ctx)
          |> wisp.html_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    ["tags"] -> {
      let posts = content.get_published_posts()
      let tags = content.get_all_tags(posts)
      renderer.render_tags_index(tags, ctx)
      |> wisp.html_response(200)
    }
    ["tags", tag] -> {
      let posts = content.get_published_posts()
      let posts_by_tag = content.get_posts_by_tag(posts)
      case dict.get(posts_by_tag, tag) {
        Ok(tagged_posts) -> {
          renderer.render_tag_page(tag, tagged_posts, ctx)
          |> wisp.html_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    ["rss.xml"] -> {
      let posts = content.get_published_posts() |> content.sort_posts()
      let rss_content = renderer.render_rss_feed(posts, ctx)
      wisp.response(200)
      |> wisp.set_header("content-type", "application/rss+xml")
      |> wisp.string_body(rss_content)
    }
    _ -> wisp.html_response(string_tree.from_string(req.path), 200)
  }
}

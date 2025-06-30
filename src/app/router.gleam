import app/renderer
import app/web.{type Context}
import gleam/string_tree
import simplifile
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> {
      let assert Ok(markdown) = simplifile.read("./priv/content/_index.md")
      renderer.render_html(markdown, ctx)
      |> wisp.html_response(200)
    }
    ["blog"] -> {
      wisp.redirect("/static/blog/index.html")
    }
    ["blog", post] -> {
      let assert Ok(markdown) =
        simplifile.read("./priv/content/blog/" <> post <> ".md")
      renderer.render_html(markdown, ctx)
      |> wisp.html_response(200)
    }
    ["tag"] -> {
      wisp.redirect("/static/tag/index.html")
    }
    ["tag", tag] -> {
      let assert Ok(markdown) =
        simplifile.read("./priv/content/tag/" <> tag <> ".md")
      renderer.render_html(markdown, ctx)
      |> wisp.html_response(200)
    }
    _ -> wisp.html_response(string_tree.from_string(req.path), 200)
  }
}

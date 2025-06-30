import app/renderer
import app/web.{type Context}
import gleam/result
import gleam/string_tree
import jot
import simplifile
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)
  case wisp.path_segments(req) {
    [] -> {
      let assert Ok(markdown) = simplifile.read("./priv/content/_index.md")
      renderer.render_html(markdown)
      |> wisp.html_response(200)
    }
    _ -> wisp.html_response(string_tree.from_string(req.path), 200)
  }
}

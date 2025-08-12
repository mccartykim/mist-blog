import app/router
import app/web
import envoy
import gleam/erlang/process
import gleam/int
import mist
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  let ctx = web.default_context(assets_directory())

  let handler = router.handle_request(_, ctx)

  let secret_key_base = "secret"

  let port = get_port()

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(port)
    |> mist.start

  process.sleep_forever()
}

fn get_port() -> Int {
  case envoy.get("PORT") {
    Ok(port_str) -> {
      case int.parse(port_str) {
        Ok(port) -> port
        Error(_) -> 8080
      }
    }
    Error(_) -> 8080
  }
}

fn assets_directory() {
  let assert Ok(priv_directory) = wisp.priv_directory("mist_blog")
  priv_directory <> "/assets"
}

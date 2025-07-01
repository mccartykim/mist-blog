import app/router
import app/web
import gleam/erlang/process
import mist
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  let ctx = web.default_context(assets_directory())

  let handler = router.handle_request(_, ctx)

  let secret_key_base = "secret"

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
}

fn assets_directory() {
  let assert Ok(priv_directory) = wisp.priv_directory("mist_blog")
  priv_directory <> "/assets"
}

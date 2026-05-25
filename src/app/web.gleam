import envoy
import gleam/result
import wisp

pub type Context {
  Context(assets_directory: String, configuration: Configuration)
}

pub type Configuration {
  Configuration(
    title: String,
    description: String,
    author: String,
    email: String,
    base_url: String,
    copyright: String,
    generator: String,
    language: String,
  )
}

/// Build a Configuration from BLOG_* environment variables, falling back to
/// generic placeholder defaults when a variable is unset. Deployments inject
/// real identity via the NixOS module so the OSS source stays free of
/// personal data.
pub fn config_from_env() -> Configuration {
  Configuration(
    title: envoy.get("BLOG_TITLE") |> result.unwrap("My Blog"),
    description: envoy.get("BLOG_DESCRIPTION")
      |> result.unwrap("A blog built with Gleam"),
    author: envoy.get("BLOG_AUTHOR") |> result.unwrap("Author Name"),
    email: envoy.get("BLOG_EMAIL") |> result.unwrap("author@example.com"),
    base_url: envoy.get("BLOG_BASE_URL")
      |> result.unwrap("https://example.com"),
    copyright: envoy.get("BLOG_COPYRIGHT")
      |> result.unwrap("Author Name (CC BY 4.0)"),
    generator: envoy.get("BLOG_GENERATOR") |> result.unwrap("Made with Gleam"),
    language: envoy.get("BLOG_LANGUAGE") |> result.unwrap("en-US"),
  )
}

pub fn default_context(assets_directory: String) -> Context {
  Context(assets_directory, config_from_env())
}

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/assets", from: ctx.assets_directory)

  handle_request(req)
}

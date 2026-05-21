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

pub const blog_configuration = Configuration(
  title: "My Blog",
  description: "A blog built with Gleam",
  author: "Author Name",
  email: "author@example.com",
  base_url: "https://example.com",
  copyright: "Author Name (CC BY 4.0)",
  generator: "Made with Gleam",
  language: "en-US",
)

pub fn default_context(assets_directory: String) -> Context {
  Context(assets_directory, blog_configuration)
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

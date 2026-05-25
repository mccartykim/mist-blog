import app/web
import envoy
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let name = "Joe"
  let greeting = "Hello, " <> name <> "!"

  assert greeting == "Hello, Joe!"
}

const blog_env_vars = [
  "BLOG_TITLE", "BLOG_DESCRIPTION", "BLOG_AUTHOR", "BLOG_EMAIL", "BLOG_BASE_URL",
  "BLOG_COPYRIGHT", "BLOG_GENERATOR", "BLOG_LANGUAGE",
]

fn clear_blog_env() -> Nil {
  clear_keys(blog_env_vars)
}

fn clear_keys(keys: List(String)) -> Nil {
  case keys {
    [] -> Nil
    [k, ..rest] -> {
      envoy.unset(k)
      clear_keys(rest)
    }
  }
}

pub fn config_from_env_defaults_test() {
  clear_blog_env()

  let cfg = web.config_from_env()

  assert cfg.title == "My Blog"
  assert cfg.description == "A blog built with Gleam"
  assert cfg.author == "Author Name"
  assert cfg.email == "author@example.com"
  assert cfg.base_url == "https://example.com"
  assert cfg.copyright == "Author Name (CC BY 4.0)"
  assert cfg.generator == "Made with Gleam"
  assert cfg.language == "en-US"
}

pub fn config_from_env_full_override_test() {
  clear_blog_env()

  envoy.set("BLOG_TITLE", "Custom Title")
  envoy.set("BLOG_DESCRIPTION", "Custom Description")
  envoy.set("BLOG_AUTHOR", "Custom Author")
  envoy.set("BLOG_EMAIL", "custom@example.org")
  envoy.set("BLOG_BASE_URL", "https://custom.example.org")
  envoy.set("BLOG_COPYRIGHT", "Custom Author (CC BY-SA 4.0)")
  envoy.set("BLOG_GENERATOR", "Custom Generator")
  envoy.set("BLOG_LANGUAGE", "fr-FR")

  let cfg = web.config_from_env()

  assert cfg.title == "Custom Title"
  assert cfg.description == "Custom Description"
  assert cfg.author == "Custom Author"
  assert cfg.email == "custom@example.org"
  assert cfg.base_url == "https://custom.example.org"
  assert cfg.copyright == "Custom Author (CC BY-SA 4.0)"
  assert cfg.generator == "Custom Generator"
  assert cfg.language == "fr-FR"

  clear_blog_env()
}

pub fn config_from_env_partial_override_test() {
  clear_blog_env()

  envoy.set("BLOG_AUTHOR", "Partial Author")
  envoy.set("BLOG_COPYRIGHT", "Partial Author (CC BY 4.0)")

  let cfg = web.config_from_env()

  assert cfg.author == "Partial Author"
  assert cfg.copyright == "Partial Author (CC BY 4.0)"
  // Unset fields keep their defaults
  assert cfg.title == "My Blog"
  assert cfg.email == "author@example.com"
  assert cfg.language == "en-US"

  clear_blog_env()
}

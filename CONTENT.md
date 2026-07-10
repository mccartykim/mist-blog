# Content Management

This document explains how to manage blog content for different environments (development vs production/public repository).

## Content Directory Structure

```
priv/content/
├── blog/           # Blog posts (Djot with frontmatter)
└── _index.md       # Homepage content
```

(Static assets live at `priv/assets/`, not under `priv/content/`.)

## Environment-Specific Content

### Development Environment
When running locally or in development, you can have:
- Draft posts (`draft: true` in frontmatter)
- Personal content
- Work-in-progress articles

### Public Repository
When sharing the repository publicly:
- All content in `priv/content/` will be included
- Draft posts are filtered out by the application
- However, the files themselves are still visible in the repository

## Best Practices for Public Sharing

### Option 1: Keep Content Separate
1. Keep your personal blog content in a separate repository
2. Use the public mist-blog repository only for the generator code
3. When deploying your personal blog, use the public generator

### Option 2: Use Symlinks in Production
In your production deployment:
```bash
# Create content directory outside the repo
mkdir -p /path/to/your-blog-content
ln -s /path/to/your-blog-content priv/content/blog
```

This way:
- The repository stays clean and generic
- Your personal content lives separately
- The generator code can be shared publicly

### Option 3: Conditional Content Loading
Modify the application to load content from:
1. `priv/content/blog/` (defaults included in repo)
2. Environment variable path (external personal content)

Example implementation (mirrors `content.gleam` lines 113-121):
```gleam
// In content.gleam
fn content_root() -> String {
  case envoy.get("BLOG_CONTENT_DIR") {
    Ok(dir) -> dir
    Error(_) -> {
      let assert Ok(priv_dir) = wisp.priv_directory("mist_blog")
      priv_dir <> "/content"
    }
  }
}
```

## Draft Posts
Posts with `draft: true` in their frontmatter are:
- Excluded from the public blog
- Still included in the repository (visible in git history)
- Can be viewed locally during development

## Personal Content
For content you never want to share:
1. Keep it outside the repository
2. Use symlinks or environment variables to load it
3. Don't commit personal content to version control
# Mist Blog - A Gleam Static Site Generator

[![Package Version](https://img.shields.io/hexpm/v/mist_blog)](https://hex.pm/packages/mist_blog)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/mist_blog)

A Gleam-based static site generator that builds personal blogs using the Mist HTTP server and Wisp web framework. Content is stored as Markdown files with YAML frontmatter.

## Features

- **Static Site Generation**: Convert Markdown files to HTML
- **YAML Frontmatter**: Metadata support for posts (title, date, tags, draft status)
- **Tag System**: Automatic tag aggregation and filtering
- **RSS Feed**: Generate XML RSS feed for blog posts
- **Server-Side Rendering**: Built-in web server using Mist and Wisp
- **Nix Support**: Flake-based development environment

## Quick Start

### Using Nix (Recommended)

```bash
# Clone and run
git clone <repository-url>
cd mist-blog
nix run .#

# Or build with Nix
nix build .#
```

### Using Gleam Directly

```bash
# Clone and set up
git clone <repository-url>
cd mist-blog
gleam deps download
gleam run
```

The server runs on port 8080 by default.

## Development

```bash
# Install dependencies
gleam deps download

# Run the server
gleam run

# Run tests
gleam test

# Format code
gleam format src test

# Check with Nix
nix flake check
```

## Content Structure

Blog posts are stored in `priv/content/blog/` as Markdown files with YAML frontmatter:

```markdown
---
title: "My First Post"
date: 2024-01-01
tags: [greeting, welcome]
draft: false
---

# Post Content

Write your post content here in Markdown.
```

### Frontmatter Fields

- `title`: Post title (required)
- `date`: Publication date (YYYY-MM-DD format)
- `tags`: Array of tags for categorization
- `draft`: Set to `true` to exclude from published site

> **Note**: For production deployments, consider keeping personal content separate from the repository using symlinks or environment variables. See [CONTENT.md](CONTENT.md) for details.

### Frontmatter Fields

- `title`: Post title (required)
- `date`: Publication date (YYYY-MM-DD format)
- `tags`: Array of tags for categorization
- `draft`: Set to `true` to exclude from published site

## Architecture

```
src/
├── mist_blog.gleam        # Main entry point and server
├── app/
│   ├── router.gleam       # HTTP routing
│   ├── content.gleam      # Markdown/YAML parsing
│   └── renderer.gleam     # HTML generation
└── app/web.gleam         # Web configuration
```

### Key Components

1. **Router** (`src/app/router.gleam`):
   - `/` - Homepage
   - `/blog` - Blog index
   - `/blog/{slug}` - Individual post
   - `/tags` - Tag index
   - `/tags/{tag}` - Posts by tag
   - `/rss.xml` - RSS feed

2. **Content System** (`src/app/content.gleam`):
   - Parses Markdown with YAML frontmatter
   - Handles draft post filtering
   - Manages tag aggregation

3. **Renderer** (`src/app/renderer.gleam`):
   - Generates HTML using Lustre
   - Embedded CSS styling
   - Responsive layout

## Configuration

Edit `src/app/web.gleam` to customize:

```gleam
pub const blog_title = "My Blog"
pub const blog_author = "Author Name"
pub const blog_description = "Blog description"
```

## License

MIT - See LICENSE file for details.
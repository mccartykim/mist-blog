# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Gleam-based blog application that serves kimb.dev. It uses the Mist HTTP server and Wisp web framework to dynamically render content from markdown files.

## Essential Commands

### Running the Application

```bash
# Using Nix (recommended)
nix run .#

# Using Gleam directly
gleam run
```

The server runs on port 8080.

### Development Commands

```bash
# Install dependencies
gleam deps download

# Run tests
gleam test

# Format code
gleam format src test

# Check the entire project with Nix
nix flake check
```

## Architecture Overview

The application follows a simple web server architecture:

1. **Entry Point** (`src/mist_blog.gleam`): Configures logging and starts the Mist server on port 8080
2. **Router** (`src/app/router.gleam`): Handles HTTP routing with these paths:
   - `/` - Homepage
   - `/blog` - Blog index  
   - `/blog/{post}` - Individual posts
   - `/tags` - Tag index
   - `/tags/{tag}` - Posts filtered by tag
   - `/rss.xml` - RSS feed
3. **Content System** (`src/app/content.gleam`): Parses markdown files with YAML frontmatter from `priv/content/`
4. **Renderer** (`src/app/renderer.gleam`): Generates HTML using Lustre; CSS is served as an external stylesheet from priv/assets/

### Key Design Patterns

- **Content Storage**: Markdown files in `priv/content/blog/` with YAML frontmatter containing title, date, tags, and draft status
- **Tag System**: Posts can have multiple tags (comma-separated in frontmatter), with automatic aggregation
- **Draft Support**: Posts with `draft: true` are excluded from publication
- **Static Assets**: CSS and other assets served from `priv/assets/`
- **Configuration**: Blog identity (title, author, etc.) is read from `BLOG_*` env vars in `src/app/web.gleam` (`config_from_env`); deployments inject real values via the `services.mist-blog` NixOS options, not by editing web.gleam

### Important Implementation Details

- The server uses Wisp as the web framework and Mist as the HTTP server
- All HTML is server-side rendered using Lustre
- CSS is embedded directly in the HTML (no external stylesheets)
- Content is Djot rendered via the jot library; frontmatter is parsed by an in-file simplified parser (no external YAML library — there is no yaml dep in gleam.toml)
- File operations use simplifile for cross-platform compatibility
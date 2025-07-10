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
4. **Renderer** (`src/app/renderer.gleam`): Generates HTML using Lustre with embedded CSS styling

### Key Design Patterns

- **Content Storage**: Markdown files in `priv/content/blog/` with YAML frontmatter containing title, date, tags, and draft status
- **Tag System**: Posts can have multiple tags (comma-separated in frontmatter), with automatic aggregation
- **Draft Support**: Posts with `draft: true` are excluded from publication
- **Static Assets**: CSS and other assets served from `priv/assets/`
- **Configuration**: Blog metadata (title, author, etc.) defined in `src/app/web.gleam`

### Important Implementation Details

- The server uses Wisp as the web framework and Mist as the HTTP server
- All HTML is server-side rendered using Lustre
- CSS is embedded directly in the HTML (no external stylesheets)
- Content parsing uses the jot library for markdown and yaml library for frontmatter
- File operations use simplifile for cross-platform compatibility

## Legacy Code

The `priv/` directory contains a standalone Nix-based static site generator from a previous version of the blog. This is no longer connected to the main application and can be ignored.
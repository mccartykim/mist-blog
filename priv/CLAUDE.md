# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

### Building the blog
```bash
nix build .#kimb_blog
```

### Running the development server
```bash
nix run .#kimb_blog_server
# Blog will be available at http://localhost:8080
```

### Running tests
```bash
# Run all tests (unit + integration)
nix flake check

# Build and view test results
nix build .#checks.x86_64-linux.unit-tests
nix build .#checks.x86_64-linux.integration-tests
```

### Building Docker image for deployment
```bash
nix build .#serve_kimb_blog
# This creates a Docker image for Fly.io deployment
```

### Deploy to Fly.io
```bash
nix develop  # Enter dev shell with flyctl
flyctl deploy
```

## Architecture Overview

This is a pure Nix-based static site generator that replaced a Hugo blog. The entire build process is deterministic and reproducible.

### Core Components

1. **static-site-generator.nix**: The heart of the system
   - `extractMeta`: Parses YAML frontmatter from markdown files
   - `baseTemplate`, `postTemplate`, `indexTemplate`: HTML generation functions
   - `rssFeed`: Clean RSS generation using `writeTextFile` and `lib.escapeXML`
   - `sitemap`: XML sitemap generation with proper escaping
   - `processMarkdown`: Converts individual posts, filtering drafts
   - Individual derivations for each component (posts, tags, feeds)

2. **Content Structure**:
   - `/content/_index.md`: Home page content
   - `/content/blog/*.md`: Blog posts with YAML frontmatter
   - Frontmatter fields: `title`, `date`, `author`, `draft`, `tags`
   - Posts with `draft: true` are automatically excluded
   - Tags are comma-separated: `tags: nix, blog, testing`
   - Post descriptions auto-generated from first paragraph for Open Graph/RSS

3. **Build Process**:
   - All posts are sorted by date (newest first)
   - CSS from `/assets/style.css` is embedded directly into each HTML file
   - Pandoc converts markdown with `--highlight-style=tango`
   - HTML is generated using string templating in Nix
   - RSS feed (`/rss.xml`) is generated with proper RFC 822 dates and HTML content
   - Tag pages automatically generated at `/tags/` and `/tags/{tagname}/`
   - Tag cloud shows frequency-based sizing (small/medium/large)

4. **RSS and Social Media**:
   - **RSS feed** (`/rss.xml`): Generated with cleaned HTML content for feed reader compatibility
   - **RSS content cleaning**: Strips complex formatting for better readability
     - Removes: sidenotes, dialogue boxes, structural tags (`<p>`, `<div>`, `<br>`)
     - Keeps: semantic tags (`<strong>`, `<em>`, `<code>`, `<blockquote>`, `<a>`)
     - Replaces removed tags with spaces (no newlines to avoid formatting issues)
   - **Open Graph tags**: Auto-generated for social media sharing with proper URLs
   - **Twitter Cards**: Fallback to Open Graph, requires no duplication

5. **Testing Strategy**:
   - **Unit tests** (`tests/unit.nix`): Test frontmatter parser and RSS cleaning using `lib.runTests`
   - **Integration tests** (`tests/integration.nix`): Verify generated HTML structure

### Key Design Decisions

- **No runtime dependencies**: Static HTML files only need a web server
- **Embedded CSS**: No external stylesheets to load
- **Pure Nix templating**: No external template engines
- **Hermetic builds**: Pinned nixpkgs ensures reproducibility across time

### Adding New Features

When adding features to the generator:
1. Modify the appropriate template function in `static-site-generator.nix`
2. Add unit tests for any new parsing logic
3. Add integration tests to verify HTML output
4. Run `nix flake check` before committing

### Common Tasks

**Add a new blog post**:
1. Create `/content/blog/your-post.md` with frontmatter
2. Run `nix build .#kimb_blog` to generate the site
3. Preview with `nix run .#kimb_blog_server`

**Modify site configuration**:
Edit the `config` attribute set in `static-site-generator.nix`

**Change CSS styling**:
Edit `/assets/style.css` - changes are embedded during build

**Debug build issues**:
The build phase writes temporary files (e.g., `post_*.md`, `post_*.html`) which can help debug Pandoc conversion issues.

**Debug visual issues with screenshots**:
```bash
# Start dev server
nix run .#kimb_blog_server &

# Take screenshots for visual debugging
mkdir -p /tmp/screenshots
nix-shell -p chromium --run "chromium --headless --disable-gpu --screenshot=/tmp/screenshots/page.png --window-size=1200,800 http://localhost:8080/blog/your-post/"

# Kill the server when done
pkill -f "simple-http-server"
```
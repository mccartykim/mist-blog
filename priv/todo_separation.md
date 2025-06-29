# Blog Generator Separation Project

## Overview

Split the current monolithic blog into two composable Nix packages:

1. **nix-static-blog** - Reusable generator with templates and themes
2. **kimb-blog-content** - Content-only repo using the generator

This showcases Nix's composability and makes the generator reusable by others while keeping content separate from infrastructure code.

## Architecture

### Generator Repo (`nix-static-blog`)
```
├── flake.nix                    # Exports lib.mkBlog + templates
├── lib/
│   └── default.nix              # Core generator function
├── themes/
│   └── default/
│       ├── style.css            # Current CSS
│       └── templates.nix        # HTML templates
├── templates/
│   └── blog/                    # Flake template for new blogs
│       ├── flake.nix
│       ├── config.nix
│       ├── content/
│       │   ├── _index.md
│       │   └── blog/hello.md
│       └── .gitignore
├── tests/
│   ├── unit.nix
│   └── integration.nix
└── README.md
```

### Content Repo (`kimb-blog-content`)
```
├── flake.nix                    # Uses nix-static-blog generator
├── config.nix                  # Site-specific config
├── content/
│   ├── _index.md
│   └── blog/*.md
└── .github/workflows/           # CI/CD for publishing
```

## Benefits

- ✅ **Separation of concerns**: Content changes vs generator changes
- ✅ **Reusable**: Others can use `nix flake new -t github:user/nix-static-blog`
- ✅ **Composable**: Showcases Nix's function composition
- ✅ **Extensible**: Users can override with overlays
- ✅ **Focused repos**: Generator improvements vs content creation
- ✅ **Version independence**: Pin generator version in content repo

## User Experience

### Quick Start (New Users)
```bash
nix flake new -t github:yourusername/nix-static-blog my-blog
cd my-blog
nix run  # Instant working blog
```

### Advanced Customization
```nix
# In user's flake.nix
outputs = { blog-generator, ... }: {
  packages.default = blog-generator.lib.mkBlog {
    config = import ./config.nix;
    contentDir = ./content;
    overlays = [
      (self: super: {
        theme = super.theme // { css = ./custom.css; };
      })
    ];
  };
}
```

## Implementation Checklist

### Phase 1: Extract Generator
- [x] **PREP COMPLETE**: Extract constants (URLs, character names) ✅
- [x] **PREP COMPLETE**: Remove Mara character references for IP safety ✅  
- [ ] Create new `nix-static-blog` repository
- [ ] Move `static-site-generator.nix` to `lib/default.nix`
- [ ] Extract theme assets to `themes/default/`
- [ ] Create `lib.mkBlog` function with parameters:
  - [ ] `config` (site configuration with dialogue character options)
  - [ ] `contentDir` (path to content)
  - [ ] `theme` (optional theme override)
  - [ ] `overlays` (optional customizations)
- [ ] Update function to work with external content directory
- [ ] Move and adapt tests to work with extracted generator

### Phase 2: Create Template
- [ ] Create `templates/blog/` directory structure
- [ ] Write template `flake.nix` that imports generator
- [ ] Create sample `config.nix` with placeholders
- [ ] Add sample content files (`_index.md`, `hello.md`)
- [ ] Add appropriate `.gitignore` for Nix builds
- [ ] Export template in generator's `flake.nix`
- [ ] Test template with `nix flake new`

### Phase 3: Content Repo Migration
- [ ] Create new `kimb-blog-content` repository
- [ ] Move content files to new repo
- [ ] Create `config.nix` with current site configuration
- [ ] Write `flake.nix` that uses generator
- [ ] Test build process
- [ ] Set up CI/CD for auto-publishing
- [ ] Update DNS/hosting to point to new builds

### Phase 4: Documentation & Polish
- [ ] Write comprehensive README for generator
- [ ] Document overlay system with examples
- [ ] Add usage examples and screenshots
- [ ] Create blog posts about the architecture
- [ ] Add more theme options
- [ ] Consider publishing to nixpkgs flakes

### Phase 5: Optional Enhancements
- [ ] Multiple theme support
- [ ] Plugin system for additional post processors
- [ ] Template variations (minimal, full-featured, etc.)
- [ ] Integration examples (GitHub Pages, Netlify, etc.)
- [ ] Performance optimizations
- [ ] Accessibility improvements

## Technical Considerations

### Generator Function Interface
```nix
mkBlog = {
  # Required
  config,        # Site configuration
  contentDir,    # Path to content directory
  
  # Optional
  theme ? themes.default,
  overlays ? [],
  pkgs ? nixpkgs.legacyPackages.${system},
}
```

### Config Schema
```nix
{
  title = "Site Title";
  description = "Site description";
  author = "Author Name";
  email = "author@example.com";
  domain = "example.com";  # For canonical URLs
  language = "en-US";
  copyright = "Copyright notice";
  
  # Configurable dialogue characters
  dialogueCharacters = {
    questioner = { name = "Questioner"; icon = "❓"; color = "#e91e63"; };
    author = { name = "Author"; icon = "✍️"; color = "#4A7C59"; };
    reader = { name = "Reader"; icon = "👤"; color = "#2196F3"; };
    system = { name = "System"; icon = "💻"; color = "#FF9800"; };
  };
}
```

### Overlay Examples
Users can override any part of the generator:
- **Custom CSS/theme**: Override default styling
- **Modified markdown processing**: Custom Pandoc options
- **Additional post metadata**: Extra frontmatter fields
- **Custom RSS generation**: Different content cleaning
- **Modified HTML templates**: Layout changes
- **Custom dialogue characters**: Domain-specific personas (Rust community could use Mara, etc.)

### Recent Improvements
- ✅ **Constants extracted**: All hardcoded URLs and character names centralized
- ✅ **IP-safe defaults**: Generic dialogue characters (questioner/author/reader/system)
- ✅ **RSS content cleaning**: Proper HTML cleaning for feed compatibility
- ✅ **Open Graph support**: Auto-generated social media meta tags
- ✅ **Comprehensive testing**: Unit tests for all core functionality

This separation will be a fantastic demonstration of Nix's power for building composable, reusable systems!
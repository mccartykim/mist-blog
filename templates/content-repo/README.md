# mist-blog content repo

A starter content tree for [mist-blog](https://github.com/mccartykim/mist-blog).

## Authoring

Six commands, all `nix run .#<verb>`:

| Command       | What it does                                                              |
|---------------|---------------------------------------------------------------------------|
| `new <slug>`  | Scaffold `content/blog/<slug>.md` with `draft: true`                      |
| `touch <slug>`| Bump `modified:` to now (leaves `date:` alone)                            |
| `publish <slug>` | Flip `draft: true` → `false` and bump both `date:` and `modified:`     |
| `set-draft <slug> <true\|false>` | Flip the draft flag without touching dates              |
| `preview <slug>` | Spin up a local server, print the URL                                  |
| `list [drafts\|published\|all]` | Enumerate posts in a table                              |

None of these touch VCS. After editing, commit your changes manually with
whatever VCS you use (git, jj, mercurial, none of the above).

## Deploying

This repo is consumed as a non-flake input by a NixOS deployer:

```nix
# In your deployment flake:
inputs.my-blog-content.url = "github:you/your-content-repo";
inputs.my-blog-content.flake = false;
# ...
services.mist-blog = {
  enable = true;
  contentDir = "${inputs.my-blog-content}/content";
  title = "your blog";
  # ...other identity options
};
```

See `nixosModules.default` exported by mist-blog for all available options.

## Where does what live

```
content/
  _index.md          # Homepage content
  blog/
    *.md             # One file per post; slug = basename without .md
flake.nix            # Imports mist-blog, re-exports its apps
```

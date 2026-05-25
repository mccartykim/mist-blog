{ lib, pkgs, config, self, ... }:
with lib;
let
  cfg = config.services.mist-blog;
in {
  options.services.mist-blog = {
    enable = mkEnableOption "mist blog server";

    contentDir = mkOption {
      type = types.path;
      description = "Path to blog content directory (must contain _index.md and blog/)";
    };

    port = mkOption {
      type = types.int;
      default = 8080;
      description = "Port to listen on";
    };

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to bind to";
    };

    title = mkOption {
      type = types.str;
      default = "My Blog";
      description = "Blog title (BLOG_TITLE)";
    };

    description = mkOption {
      type = types.str;
      default = "A blog built with Gleam";
      description = "Blog description (BLOG_DESCRIPTION)";
    };

    author = mkOption {
      type = types.str;
      default = "Author Name";
      description = "Blog author name (BLOG_AUTHOR)";
    };

    email = mkOption {
      type = types.str;
      default = "author@example.com";
      description = "Blog author email (BLOG_EMAIL)";
    };

    baseUrl = mkOption {
      type = types.str;
      default = "https://example.com";
      description = "Canonical base URL of the deployed blog (BLOG_BASE_URL)";
    };

    copyright = mkOption {
      type = types.str;
      default = "Author Name (CC BY 4.0)";
      description = "Footer copyright string (BLOG_COPYRIGHT)";
    };

    generator = mkOption {
      type = types.str;
      default = "Made with Gleam";
      description = "Footer generator string (BLOG_GENERATOR)";
    };

    language = mkOption {
      type = types.str;
      default = "en-US";
      description = "BCP-47 language tag (BLOG_LANGUAGE)";
    };

    wikilinkBase = mkOption {
      type = types.str;
      default = "/blog/";
      description = ''
        Base path prepended to Obsidian-style wikilink slugs when
        pre-rendering them to Djot links (BLOG_WIKILINK_BASE). For example,
        with the default `/blog/`, `[[foo]]` becomes a link to `/blog/foo`.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.mist-blog = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = {
        BLOG_CONTENT_DIR = cfg.contentDir;
        PORT = toString cfg.port;
        HOST = cfg.host;
        BLOG_TITLE = cfg.title;
        BLOG_DESCRIPTION = cfg.description;
        BLOG_AUTHOR = cfg.author;
        BLOG_EMAIL = cfg.email;
        BLOG_BASE_URL = cfg.baseUrl;
        BLOG_COPYRIGHT = cfg.copyright;
        BLOG_GENERATOR = cfg.generator;
        BLOG_LANGUAGE = cfg.language;
        BLOG_WIKILINK_BASE = cfg.wikilinkBase;
      };
      serviceConfig = {
        ExecStart = "${self.packages.${pkgs.system}.default}/bin/mist_blog";
        Restart = "always";
        Type = "simple";
      };
    };
  };
}

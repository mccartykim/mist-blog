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
  };

  config = mkIf cfg.enable {
    systemd.services.mist-blog = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = {
        BLOG_CONTENT_DIR = cfg.contentDir;
        PORT = toString cfg.port;
        HOST = cfg.host;
      };
      serviceConfig = {
        ExecStart = "${self.packages.${pkgs.system}.default}/bin/mist_blog";
        Restart = "always";
        Type = "simple";
      };
    };
  };
}

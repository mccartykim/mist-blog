{ lib, pkgs, config, self, ... }:
with lib;
let
  cfg = config.services.mist-blog;
in {
  options.services.mist-blog = {
    enable = mkEnableOption "mist blog server";
    # TODO add support for external content repo
  };

  config = mkIf cfg.enable {
    systemd.services.mist-blog = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.mist-blog}/bin/mist-blog";
        Restart = "always";
        Type = "simple";
      };
    };
  };
}

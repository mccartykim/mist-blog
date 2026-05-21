{
  description = "A Gleam-based static site generator built with Mist and Wisp";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nix-gleam.url = "github:arnarg/nix-gleam";

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nix-gleam,
    }:
    (flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Call nix-gleam's builder directly with only Linux dependencies
        gleamBuilder = pkgs.callPackage "${nix-gleam}/builder" {
          # Explicitly provide only the dependencies we want, excluding Darwin
          # The builder should work with just these core dependencies
        };
        buildGleamApplication = gleamBuilder.buildGleamApplication;
        
        mist_blog = buildGleamApplication {
          src = ./.;
        };
      in
      {
        packages.default = mist_blog;
        packages.mist-blog = mist_blog;
        packages.mist_blog_container = pkgs.dockerTools.streamLayeredImage {
          name = "mist-blog";
          contents = [ mist_blog ];
          config = {
            Cmd = [ "/bin/mist_blog" ];
          };
        };
      }
    )) // {
        nixosModules.default = import ./module/server.nix;
    };
}

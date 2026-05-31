{
  description = "A mist-blog content repo";

  inputs.mist-blog.url = "github:mccartykim/mist-blog";
  inputs.nixpkgs.follows = "mist-blog/nixpkgs";
  inputs.flake-utils.follows = "mist-blog/flake-utils";

  outputs =
    {
      self,
      mist-blog,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system: {
      # Re-export the engine's authoring apps. Each defaults
      # BLOG_CONTENT_DIR to ./content when invoked from this repo's root, so
      # `nix run .#new -- hello-world` writes into ./content/blog/.
      apps = mist-blog.apps.${system};

      # All six commands as a single derivation, for users who want them on
      # PATH via home-manager or a project devShell elsewhere.
      packages.scripts = mist-blog.packages.${system}.scripts;

      # `nix develop` drops you into a shell with `mist-blog-new`,
      # `mist-blog-publish`, etc. all on PATH.
      devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
        packages = [ mist-blog.packages.${system}.scripts ];
      };
    });
}

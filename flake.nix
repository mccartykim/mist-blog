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

        # Re-uses the package build (deps, configure, gleam export) and adds a
        # checkPhase that runs `gleam test`. Exposed under `checks` so
        # `nix flake check` fails the flake when any test fails.
        mist_blog_tests = mist_blog.overrideAttrs (old: {
          pname = "${old.pname}-tests";
          doCheck = true;
          checkPhase = ''
            runHook preCheck
            gleam test
            runHook postCheck
          '';
        });

        # --- Authoring CLI scripts ----------------------------------------
        #
        # Each script is wrapped with `pkgs.writeShellApplication`, which
        # runs shellcheck at build time and pins the script's PATH to
        # exactly what's listed in `runtimeInputs`.
        #
        # Scripts that mutate frontmatter through `scripts/_frontmatter.awk`
        # get the awk file's store path via the `FRONTMATTER_AWK` env var.
        # The bash sources fall back to a sibling path when the env var is
        # unset, so they remain runnable standalone for unit testing outside
        # Nix.

        frontmatterAwk = ./scripts/_frontmatter.awk;

        mkScript =
          { name, source, runtimeInputs, needsAwk ? false }:
          pkgs.writeShellApplication {
            name = "mist-blog-${name}";
            inherit runtimeInputs;
            text =
              (if needsAwk then ''export FRONTMATTER_AWK="${frontmatterAwk}"'' + "\n" else "")
              + builtins.readFile source;
          };

        scripts = {
          new = mkScript {
            name = "new";
            source = ./scripts/new.sh;
            runtimeInputs = with pkgs; [ coreutils ];
          };
          touch = mkScript {
            name = "touch";
            source = ./scripts/touch.sh;
            runtimeInputs = with pkgs; [ coreutils gawk ];
            needsAwk = true;
          };
          publish = mkScript {
            name = "publish";
            source = ./scripts/publish.sh;
            runtimeInputs = with pkgs; [ coreutils gawk ];
            needsAwk = true;
          };
          set-draft = mkScript {
            name = "set-draft";
            source = ./scripts/set-draft.sh;
            runtimeInputs = with pkgs; [ coreutils gawk ];
            needsAwk = true;
          };
          preview = mkScript {
            name = "preview";
            source = ./scripts/preview.sh;
            runtimeInputs = [ pkgs.coreutils pkgs.curl mist_blog ];
          };
          list = mkScript {
            name = "list";
            source = ./scripts/list.sh;
            runtimeInputs = with pkgs; [ coreutils gawk ];
          };
        };

        scriptsBundle = pkgs.symlinkJoin {
          name = "mist-blog-scripts";
          paths = builtins.attrValues scripts;
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
        packages.scripts = scriptsBundle;

        apps = builtins.mapAttrs (name: drv: {
          type = "app";
          program = "${drv}/bin/mist-blog-${name}";
        }) scripts;

        checks.tests = mist_blog_tests;
      }
    )) // {
        nixosModules.default = import ./module/server.nix;

        templates.content-repo = {
          path = ./templates/content-repo;
          description = "A starter content repo for mist-blog (re-exports the engine's authoring apps and ships a sample post)";
        };
    };
}

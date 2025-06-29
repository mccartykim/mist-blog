{
  inputs = {
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      # The generator returns both the blog and internal functions
      generator = pkgs.callPackage ./static-site-generator.nix {};
      kimb_blog = generator;  # When used as derivation, Nix uses the main attrs
      kimb_blog_server = pkgs.writeShellApplication {

        name = "serve_kimb_blog";
	runtimeInputs = [ kimb_blog pkgs.simple-http-server ];
	text = ''
          ${pkgs.simple-http-server}/bin/simple-http-server -p 8080 -i ${kimb_blog}/
      ''; };
    in
    {
      packages.kimb_blog = kimb_blog;
      packages.kimb_blog_server = kimb_blog_server;
      packages.serve_kimb_blog = pkgs.dockerTools.streamLayeredImage {
        name = "registry.fly.io/kimb-blog";
	tag = "current";
	contents = kimb_blog_server;
	config.Cmd = [ "/bin/serve_kimb_blog" ];
      };
      # Tests using the proper checks attribute for nix flake check
      checks = {
        # Unit tests using lib.runTests
        unit-tests = 
          let 
            testResults = import ./tests/unit.nix { 
              lib = pkgs.lib; 
              inherit generator;
            };
          in
          if testResults == []
          then pkgs.runCommand "unit-tests-passed" {} ''
            echo "All unit tests passed!" > $out
          ''
          else pkgs.runCommand "unit-tests-failed" {} ''
            echo "Unit tests failed:"
            echo "${pkgs.lib.concatStringsSep "\n" (map (result: "${result.name}: expected ${toString result.expected}, got ${toString result.result}") testResults)}"
            exit 1
          '';
        
        # Integration tests
        integration-tests = pkgs.callPackage ./tests/integration.nix { 
          ssg = kimb_blog;
        };
      };
      
      devShells.default = pkgs.mkShell {
        buildInputs = [
	  pkgs.flyctl
	  kimb_blog 
        ];

      };
    }
  );
}

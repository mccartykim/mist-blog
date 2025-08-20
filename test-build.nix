# Test script to verify mist-blog builds correctly
let
  flake = builtins.getFlake (toString ./.);
  system = "x86_64-linux";
  
  # Get the package from our flake
  package = flake.packages.${system}.default;
  
  # Simple test to verify the package builds and has expected outputs
  nixpkgs = import (builtins.getFlake "nixpkgs") { system = system; };
  testPackage = nixpkgs.stdenv.mkDerivation {
    name = "test-mist-blog";
    dontUnpack = true;
    
    buildPhase = ''
      echo "Testing mist-blog package..."
      
      # Check that the package exists
      if [ ! -d "${package}" ]; then
        echo "ERROR: Package directory does not exist"
        exit 1
      fi
      
      # Check that the binary exists
      if [ ! -f "${package}/bin/mist_blog" ]; then
        echo "ERROR: mist_blog binary not found"
        exit 1
      fi
      
      # Check that the binary is executable
      if [ ! -x "${package}/bin/mist_blog" ]; then
        echo "ERROR: mist_blog binary is not executable"
        exit 1
      fi
      
      echo "SUCCESS: mist-blog builds correctly!"
      echo "Package path: ${package}"
      echo "Binary path: ${package}/bin/mist_blog"
    '';
    
    installPhase = ''
      # Create success marker
      mkdir -p $out
      echo "mist-blog test passed" > $out/result
      echo "Package: ${package}" >> $out/result
      echo "Binary: ${package}/bin/mist_blog" >> $out/result
    '';
  };

in testPackage
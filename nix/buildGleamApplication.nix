{
  stdenv,
  lib,
  git,
  gleam,
  erlang,
  rebar3,
  elixir,
  beamPackages,
  rsync,
  nodejs,
  fetchHex,
  fetchFromGitHub,
}:

{ src
, pname ? null
, version ? null
, target ? null
, erlangPackage ? erlang
, nativeBuildInputs ? []
, localPackages ? {}
, ...
}@args:

let
  inherit (builtins) readFile fromTOML;
  inherit (lib) 
    removeAttrs hasAttr optionalString 
    concatStringsSep mapAttrsToList 
    optionalAttrs;

  # Read and parse gleam.toml
  gleamToml = fromTOML (readFile "${src}/gleam.toml");
  
  # Extract package info
  finalPname = if pname != null then pname else gleamToml.name;
  finalVersion = if version != null then version else gleamToml.version;
  finalTarget = if target != null then target else (gleamToml.target or "erlang");

  # Simplified dependency handling - just use what's available
  buildInputs = [
    gleam
    erlangPackage
    rebar3
    git
  ] ++ (if finalTarget == "javascript" then [ nodejs ] else []);

in stdenv.mkDerivation (removeAttrs args [
  "localPackages"
  "erlangPackage"
] // {
  inherit finalPname finalVersion;
  name = "${finalPname}-${finalVersion}";
  
  nativeBuildInputs = nativeBuildInputs ++ buildInputs;

  buildPhase = ''
    runHook preBuild
    
    # Set up Gleam environment
    export GLEAM_VERSION="${gleam.version}"
    export GLEAM_TARGET="${finalTarget}"
    
    # Build the project
    gleam build
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin
    
    if [ "${finalTarget}" = "erlang" ]; then
      # For Erlang target, copy the built beam files and create a wrapper script
      mkdir -p $out/lib/${finalPname}
      cp -r build/prod/erlang/${finalPname}/* $out/lib/${finalPname}/
      
      # Create executable wrapper
      cat > $out/bin/${finalPname} << EOF
#!/bin/sh
exec ${erlangPackage}/bin/erl -pa $out/lib/${finalPname}/ebin -noshell -s ${builtins.replaceStrings ["-"] ["_"] finalPname} main -s init stop
EOF
      chmod +x $out/bin/${finalPname}
    else
      # For JavaScript target
      cp build/prod/javascript/${finalPname}.mjs $out/bin/${finalPname}
      chmod +x $out/bin/${finalPname}
    fi
    
    runHook postInstall
  '';

  meta = with lib; {
    description = gleamToml.description or "A Gleam application";
    homepage = gleamToml.repository or "";
    license = licenses.mit; # Default to MIT, adjust as needed
    maintainers = [ ];
    platforms = platforms.unix;
  };
})
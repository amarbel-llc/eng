{ pkgs ? import <nixpkgs> {} }:

let
  # The Nixpkgs set with supporting libraries for Rust
  rustpkgs = pkgs.rustPlatform;

  # --- 1. Fetch the source from GitHub ---
  src = pkgs.fetchFromGitHub {
    owner = "iffse";
    repo = "pay-respects";
    # You should use a specific, stable version tag (e.g., "v0.9.1")
    # Replace the revision (rev) with the commit hash or tag you want to use.
    rev = "v0.9.1";
    # The sha256 must match the content of the rev.
    # If the build fails, run `nix-prefetch-github iffse pay-respects --rev v0.9.1`
    # to get the correct hash, and replace the value below.
    sha256 = "sha256-4c4y/YF02y1FwQvK2N61p3uO6x1fL3i7jQ7i9c7b94g=";
  };

  # --- 2. Define the Runtime Rules Module Derivation ---
  # This builds the separate module binary.
  payRespectsModuleRuntimeRules = rustpkgs.buildRustPackage {
    pname = "pay-respects-module-runtime-rules";
    version = "0.9.1"; # Must match the rev above
    inherit src;
    # Tell Nix to look for the crate in the module-runtime-rules subdirectory
    sourceRoot = "${src.name}/module-runtime-rules";
  };

  # --- 3. Define the Core Application Derivation ---
  payRespectsCore = rustpkgs.buildRustPackage {
    pname = "pay-respects-core";
    version = "0.9.1"; # Must match the rev above
    inherit src;
    # Tell Nix to look for the crate in the core subdirectory
    sourceRoot = "${src.name}/core";
    # Specify the name of the binary to install
    cargoBuildFlags = [ "--bin" "pay-respects" ];
  };

  # --- 4. Create the Final Package with the Module Included ---
  # This creates a single package containing the core binary and the module binary.
  payRespects = pkgs.symlinkJoin {
    name = "pay-respects-with-runtime-rules-${payRespectsCore.version}";
    
    # Include the core application
    paths = [ payRespectsCore ];

    # Add `makeWrapper` as a dependency for the post-build script
    nativeBuildInputs = [ pkgs.makeWrapper ];
    
    # Use postBuild to install the module and wrap the main executable
    postBuild = ''
      # 1. Create the standard module directory that pay-respects checks
      local moduleDir="$out/lib/pay-respects/modules"
      mkdir -p "$moduleDir"
      
      # 2. Copy the built module binary into the module directory
      # The installed binary name is derived from the crate name: pay-respects-module-runtime-rules
      cp ${payRespectsModuleRuntimeRules}/bin/pay-respects-module-runtime-rules "$moduleDir"/
      
      # 3. Wrap the main binary to set the _PR_LIB environment variable,
      # pointing to the module's location to ensure the core application finds it.
      wrapProgram $out/bin/pay-respects \
        --set _PR_LIB "$moduleDir"
    '';
  };
in payRespects

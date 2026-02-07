{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    # explicitly included separately
    # explicit-chrest.url = "github:friedenberg/chrest?dir=go";
    dodder.url = "github:friedenberg/dodder?dir=go";
    explicit-ssh-agent-mux.url = "github:friedenberg/ssh-agent-mux";
    explicit-glyphs-agent-mux.url = "github:friedenberg/glyphs";

    # implicitly required by flake tree
    brew.url = "github:BatteredBunny/brew-nix";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.21.tar.gz";
    gomod2nix.url = "github:nix-community/gomod2nix";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      utils,
      ...
    }@inputs:
    (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Helper functions remain the same
        getFlakesInDir =
          dir:
          let
            entries = builtins.readDir (self + "/${dir}");
            flakeDirs = builtins.filter (
              name: entries.${name} == "directory" && builtins.pathExists (self + "/${dir}/${name}/flake.nix")
            ) (builtins.attrNames entries);
          in
          map (name: {
            inherit name;
            path = "${dir}/${name}";
          }) flakeDirs;

        pkgDirs =
          let
            pkgsEntries = builtins.readDir (self + "/pkgs");
            dirs = builtins.filter (name: pkgsEntries.${name} == "directory") (builtins.attrNames pkgsEntries);
          in
          builtins.sort builtins.lessThan dirs;

        orderedFlakes = builtins.concatLists (map (dir: getFlakesInDir "pkgs/${dir}") pkgDirs);

        # Modified resolution logic
        resolvedFlakes = builtins.foldl' (
          acc: flakeInfo:
          let
            flakeNix = import (self + "/${flakeInfo.path}/flake.nix");
            expectedArgs = builtins.functionArgs flakeNix.outputs;
            flakeSelf = self + "/${flakeInfo.path}";

            # Build available inputs
            availableInputs = {
              self = flakeSelf;
              inherit nixpkgs nixpkgs-stable utils;
            }
            // acc
            // inputs; # acc has resolved monorepo flakes, inputs has external

            # For child flake inputs that reference other monorepo flakes,
            # create a mapping function
            resolveMonorepoInput =
              inputName: inputSpec:
              if acc ? ${inputName} then
                acc.${inputName} # Already resolved monorepo flake
              else if inputs ? ${inputName} then
                inputs.${inputName} # External input passed from top-level
              else if builtins.isAttrs inputSpec && inputSpec ? follows then
                # Handle follows declarations
                let
                  followPath = pkgs.lib.splitString "." inputSpec.follows;
                in
                pkgs.lib.getAttrFromPath followPath availableInputs
              else
                # For URL-based inputs in child flakes, you need to either:
                # 1. Add them as top-level inputs, or
                # 2. Use a dummy/mock value, or
                # 3. Throw an error
                throw "Cannot resolve input ${inputName} for ${flakeInfo.name} - add it to top-level inputs";

            # Build the inputs for this flake
            flakeInputs =
              let
                # Start with what we can directly provide
                directInputs = pkgs.lib.filterAttrs (name: _: builtins.hasAttr name expectedArgs) availableInputs;

                # Add any missing inputs that are defined in the flake itself
                childDefinedInputs =
                  if flakeNix ? inputs then pkgs.lib.mapAttrs resolveMonorepoInput flakeNix.inputs else { };
              in
              directInputs
              // (pkgs.lib.filterAttrs (
                name: _: builtins.hasAttr name expectedArgs && !(directInputs ? ${name})
              ) childDefinedInputs);

            flakeOutputs = flakeNix.outputs flakeInputs;
          in
          acc // { ${flakeInfo.name} = flakeOutputs; }
        ) { } orderedFlakes;

        # Rest remains the same...
        localPackages = pkgs.lib.filterAttrs (n: v: v != null) (
          builtins.mapAttrs (
            name: flake:
            if name == "system-linux" && !pkgs.stdenv.isLinux then
              null
            else if name == "system-darwin" && !pkgs.stdenv.isDarwin then
              null
            else
              flake.packages.${system}.default or null
          ) resolvedFlakes
        );

        explicitInputs = pkgs.lib.filterAttrs (name: _: pkgs.lib.hasPrefix "explicit-" name) inputs;

        # Extract packages from explicit inputs
        explicitPackages = builtins.listToAttrs (
          builtins.filter (x: x.value != null) (
            map (
              name:
              let
                # Remove the "explicit-" prefix for the package name
                packageName = pkgs.lib.removePrefix "explicit-" name;
                flake = inputs.${name};
              in
              {
                name = packageName;
                value = flake.packages.${system}.default or null;
              }
            ) (builtins.attrNames explicitInputs)
          )
        );
      in
      {
        packages =
          localPackages
          // explicitPackages
          // {
            default = pkgs.symlinkJoin {
              failOnMissing = true;
              name = "source";
              paths = (builtins.attrValues localPackages) ++ (builtins.attrValues explicitPackages);
            };
          };
      }
    ));
}

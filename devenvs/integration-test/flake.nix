{
  description = "Integration test environment with real external services";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgs-master = import nixpkgs-master { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages =
            (with pkgs; [
              # PKCS#11 software token
              softhsm
              opensc # pkcs11-tool

              # direnv testing
              direnv

              # SSH agent testing
              openssh

              # Test runner
              bats

              # Log output
              gum

              # Build tools
              just
              jq
            ])
            ++ (with pkgs-master; [
              # Latest nix for flake testing
              nix
            ]);

          shellHook = ''
            # XDG isolation for test environment
            export INTEGRATION_TEST_TMPDIR="$(mktemp -d -t integration-test.XXXXXX)"
            export XDG_RUNTIME_DIR="$INTEGRATION_TEST_TMPDIR/run"
            export XDG_STATE_HOME="$INTEGRATION_TEST_TMPDIR/state"
            export XDG_CONFIG_HOME="$INTEGRATION_TEST_TMPDIR/config"
            export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/config"
            mkdir -p "$XDG_RUNTIME_DIR" "$XDG_STATE_HOME" "$XDG_CONFIG_HOME/git"

            # SoftHSM2 token directory
            export SOFTHSM2_CONF="$INTEGRATION_TEST_TMPDIR/softhsm2.conf"
            export SOFTHSM2_TOKEN_DIR="$INTEGRATION_TEST_TMPDIR/tokens"
            mkdir -p "$SOFTHSM2_TOKEN_DIR"
            echo "directories.tokendir = $SOFTHSM2_TOKEN_DIR" > "$SOFTHSM2_CONF"

            echo "Integration test environment ready: $INTEGRATION_TEST_TMPDIR"
          '';
        };
      }
    );
}

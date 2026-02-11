{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
    }:
    utils.lib.eachSystem
      [
        "x86_64-darwin"
        "aarch64-darwin"
      ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          packages = {
            inherit (pkgs)
              pinentry_mac
              reattach-to-user-namespace
              ;
          };
        in
        {
          packages =
            packages
            // {
              default = pkgs.symlinkJoin {
                failOnMissing = true;
                name = "system-packages";
                paths = builtins.attrValues packages;
              };
            };

          devShells.default = pkgs.mkShell {
            packages = builtins.attrValues packages;
          };
        }
      );
}

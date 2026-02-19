{
  description = "tap-dancer bash library for git aliases";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    tap-dancer = {
      url = "github:amarbel-llc/tap-dancer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      utils,
      tap-dancer,
      ...
    }:
    utils.lib.eachDefaultSystem (
      system:
      {
        packages.default = tap-dancer.packages.${system}.bash-lib;
      }
    );
}

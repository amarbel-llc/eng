{
  description = "tap-dancer bash library for git aliases";

  inputs = {
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    purse-first = {
      url = "github:amarbel-llc/purse-first";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
  };

  outputs =
    {
      nixpkgs,
      utils,
      purse-first,
      nixpkgs-master,
      ...
    }:
    utils.lib.eachDefaultSystem (
      system:
      {
        packages.default = purse-first.packages.${system}.tap-dancer;
      }
    );
}

# Build the eng circus (clown wrapper + bundled plugins) for a given system.
# Imported by ~/eng/flake.nix directly, and by ~/eng-* overlays that want
# to add extra plugins on top of the base eng plugin set.
{
  pkgs,
  inputs,
  engSelf,
  system,
  extraPlugins ? [ ],
  enableCaldav ? true,
}:
let
  inherit (pkgs) lib;

  engPlugin = pkgs.runCommand "eng-plugin" { } ''
    mkdir -p $out/share/purse-first
    cp -r ${../plugins/eng} $out/share/purse-first/eng
  '';

  engPluginFlake = {
    packages.${system}.default = engPlugin;
    rev = engSelf.rev or engSelf.dirtyRev or "dirty";
  };

  caldavPlugin = {
    flake = {
      packages.${system}.default = inputs.bob.packages.${system}.caldav;
      rev = inputs.bob.rev or inputs.bob.dirtyRev or "dirty";
    };
    dirs = [ "share/purse-first/caldav" ];
  };

  basePlugins = [
    {
      flake = inputs.moxy;
      dirs = [ "share/purse-first/moxy" ];
    }
    {
      flake = inputs.spinclass;
      dirs = [ "share/purse-first/spinclass" ];
    }
    {
      flake = engPluginFlake;
      dirs = [ "share/purse-first/eng" ];
    }
  ]
  ++ lib.optional enableCaldav caldavPlugin;

  circus = inputs.clown.lib.${system}.mkCircus {
    plugins = basePlugins ++ extraPlugins;
  };
in
{
  inherit circus engPlugin;
}

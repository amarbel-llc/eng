# Build the eng circus (clown wrapper + bundled plugins) for a given system.
# Imported by ~/eng/flake.nix directly, and by ~/eng-* overlays that want
# to add extra plugins on top of the base eng plugin set.
{
  pkgs,
  inputs,
  engSelf,
  system,
  extraPlugins ? [ ],
}:
let
  engPlugin = pkgs.runCommand "eng-plugin" { } ''
    mkdir -p $out/share/purse-first
    cp -r ${../plugins/eng} $out/share/purse-first/eng
  '';

  engPluginFlake = {
    packages.${system}.default = engPlugin;
    rev = engSelf.rev or engSelf.dirtyRev or "dirty";
  };

  caldavPluginFlake = {
    packages.${system}.default = inputs.bob.packages.${system}.caldav;
    rev = inputs.bob.rev or inputs.bob.dirtyRev or "dirty";
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
      flake = caldavPluginFlake;
      dirs = [ "share/purse-first/caldav" ];
    }
    {
      flake = engPluginFlake;
      dirs = [ "share/purse-first/eng" ];
    }
  ];
  circus = inputs.clown.lib.${system}.mkCircus {
    plugins = basePlugins ++ extraPlugins;
  };
in
{
  inherit circus engPlugin;
}

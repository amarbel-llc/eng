{
  pkgs,
  pkgs-master,
  ...
}:
let
  glow-wrapper = pkgs.writeShellScriptBin "glow" ''
    exec ${pkgs-master.glow}/bin/glow -p "$@"
  '';
in
{
  home.packages = [
    glow-wrapper
  ];
}

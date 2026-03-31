{
  pkgs,
  pkgs-master,
  ...
}:
let
  claude-wrapper = pkgs.writeShellScriptBin "claude" ''
    exec ${pkgs-master.claude-code}/bin/claude "$@"
  '';

  glow-wrapper = pkgs.writeShellScriptBin "glow" ''
    exec ${pkgs-master.glow}/bin/glow -p "$@"
  '';
in
{
  home.packages = [
    claude-wrapper
    glow-wrapper
  ];
}

{
  pkgs,
  pkgs-master,
  pkgs-claude-code-pinned,
  ...
}:
let
  # claude-code is pinned to 2.1.83 via a dedicated frozen nixpkgs input
  # (`nixpkgs-claude-code-pinned` in ../flake.nix), not tracked by
  # `nixpkgs-master`. This wrapper is the single source of the `claude`
  # entry on $PATH — systems/common.nix intentionally does not include
  # claude-code.
  claude-wrapper = pkgs.writeShellScriptBin "claude" ''
    exec ${pkgs-claude-code-pinned.claude-code}/bin/claude "$@"
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

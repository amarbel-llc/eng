{
  pkgs,
  pkgs-master,
  pkgs-claude-code-pinned,
  ...
}:
let
  # claude-code is pinned to 2.1.87 via a dedicated frozen nixpkgs input
  # (`nixpkgs-claude-code-pinned` in ../flake.nix), not tracked by
  # `nixpkgs-master`, because v2.1.89 introduced an alternate-screen buffer
  # regression that leaves terminal text overlapping on exit and kills
  # scrollback. See anthropics/claude-code#42670 / #42340. 2.1.88 would be
  # a tighter pin but its tarballs have been unpublished from npm and the
  # claude-code-bin mirror, making it unbuildable — 2.1.87 is the closest
  # fetchable version. This wrapper is the single source of the `claude`
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

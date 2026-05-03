# Single source of truth for platform-neutral package set.
#
# Imported by both:
#   - home/common.nix             (home-manager home.packages on linux + darwin)
#   - systems/common/default.nix  (eng/result symlinkJoin via flake.nix)
#
# Excluded packages (provided by dedicated modules instead):
#   - fish, git, direnv, nix-direnv  → programs.* in home/{common,fish,git}.nix
#   - kitty                          → programs.kitty in home/common.nix
#   - glow                           → glow-wrapper in home/wrappers.nix
#
# These are present in ~/.nix-profile/bin via their modules, so home-manager
# users still get them; the eng/result symlinkJoin no longer carries them.
{ pkgs, pkgs-master }:
{
  inherit (pkgs-master)
    age
    asdf
    asdf-vm
    coreutils
    curl
    dash
    eternal-terminal
    expect
    ffmpeg
    figlet
    fontconfig
    freeze
    fswatch
    gawk
    gh
    git-secret
    gnumake
    gnuplot
    gopls
    gpgme
    graphviz
    gum
    helix
    httpie
    hub
    imagemagick
    j2cli
    jinja2-cli
    jq
    just
    lftp
    markscribe
    melt
    mods
    neovim
    nixpkgs-fmt
    pandoc
    paperkey
    parallel
    pay-respects
    plantuml
    pop
    rcm
    rsync
    shellcheck
    shfmt
    silver-searcher
    skate
    socat
    sshpass
    tealdeer
    termdown
    timg
    tmux
    tree
    uv
    vhs
    watchexec
    websocat
    wget
    yt-dlp
    yubico-piv-tool
    zstd
    zx
    ;

  inherit (pkgs)
    csvkit
    ;

  # fh stays on stable nixpkgs (not pkgs-master) because pkgs-master changes
  # frequently and fh is expensive to rebuild.
  fh = pkgs.fh;
}

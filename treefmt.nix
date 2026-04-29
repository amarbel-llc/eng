# treefmt-nix module for the eng monorepo. Treated as the "global default"
# config — the wrapper at flake.nix's eachDefaultSystem block prefers
# per-project treefmt.toml when present, falls back to this baked config
# otherwise.
{
  pkgs,
  lib,
  tommy,
  ...
}:
{
  projectRootFile = "flake.nix";

  settings.global.excludes = [
    "flake.lock"
    "**/flake.lock"
    "go.sum"
    "**/go.sum"
    "Cargo.lock"
    "**/Cargo.lock"
    "vendor/**"
    "node_modules/**"
    # Generated lockfiles and similar
    "gomod2nix.toml"
    "**/gomod2nix.toml"
    # Binary / image assets that shouldn't be touched
    "*.png"
    "*.jpg"
    "*.jpeg"
    "*.gif"
    "*.svg"
    "*.ico"
    "*.pdf"
    # Files that are legitimately malformed for their declared extension:
    # HTML fragments saved as .css, JXA snippets saved as .js, YAML with
    # intentional duplicate keys. Running prettier against these crashes
    # every fmt-all invocation.
    "rcm/local/share/pandoc/defaults/email.yaml"
    "rcm/local/share/pandoc/style.css"
    "rcm/tag-darwin/Alfred.alfredpreferences/workflows/snippets/markdown/style.css"
    "rcm/tag-darwin/Alfred.alfredpreferences/workflows/dodder/vanguard.js"
  ];

  # Go: goimports → gofumpt chain. Lower priority runs first; goimports must
  # run before gofumpt so the import-grouped output is then re-canonicalized
  # by gofumpt.
  programs.goimports.enable = true;
  settings.formatter.goimports.priority = 1;
  programs.gofumpt.enable = true;
  settings.formatter.gofumpt.priority = 2;

  # Shell: bash, sh, bats. 2-space indent, simplify pass.
  programs.shfmt.enable = true;
  programs.shfmt.indent_size = 2;
  programs.shfmt.simplify = true;
  settings.formatter.shfmt.includes = [
    "*.sh"
    "*.bash"
    "*.bats"
  ];

  # C/C++ family.
  programs.clang-format.enable = true;
  settings.formatter.clang-format.includes = [
    "*.c"
    "*.h"
    "*.cc"
    "*.cpp"
    "*.hpp"
    "*.cxx"
    "*.hxx"
  ];

  # Java.
  programs.google-java-format.enable = true;

  # Lua.
  programs.stylua.enable = true;

  # Nix. Pin to nixfmt-rfc-style; treefmt-nix's default `programs.nixfmt`
  # uses `pkgs.nixfmt`, which in some nixpkgs revisions is still classic.
  programs.nixfmt.enable = true;
  programs.nixfmt.package = pkgs.nixfmt-rfc-style;

  # Rust.
  programs.rustfmt.enable = true;

  # Zig. The treefmt-nix module is marked broken on darwin upstream; gate it.
  programs.zig.enable = pkgs.stdenv.isLinux;

  # Web/data: prettier covers css/scss, html/htm, ts/tsx/js/jsx, yaml/yml.
  # Prettier also handles markdown and json by default — we don't want those
  # (jq formats json; markdown is unformatted), so the glob set is explicit.
  programs.prettier.enable = true;
  settings.formatter.prettier.includes = lib.mkForce [
    "*.css"
    "*.scss"
    "*.html"
    "*.htm"
    "*.ts"
    "*.tsx"
    "*.js"
    "*.jsx"
    "*.yaml"
    "*.yml"
  ];

  # JSON: `jq .`. jq has no native in-place mode, so wrap with a tempfile
  # round-trip. Bash trampoline pattern from treefmt-nix's README, custom
  # formatter section.
  settings.formatter.jq = {
    command = "${pkgs.bash}/bin/bash";
    options = [
      "-euc"
      ''
        for f in "$@"; do
          tmp=$(mktemp "''${f}.XXXXXX")
          ${pkgs.jq}/bin/jq . "$f" > "$tmp"
          if ! cmp -s "$f" "$tmp"; then
            mv "$tmp" "$f"
          else
            rm "$tmp"
          fi
        done
      ''
      "--" # bash swallows the second argument when using -c
    ];
    includes = [ "*.json" ];
  };

  # TOML: tommy supports native file-args mode (`tommy fmt <file> ...`), per
  # github:amarbel-llc/tommy README §CLI.
  settings.formatter.tommy = {
    command = "${tommy}/bin/tommy";
    options = [ "fmt" ];
    includes = [ "*.toml" ];
  };

  # php, python, terraform, swift, markdown have no treefmt entry by design.
  # Python formatting happens via pylsp's ruff in the editor; the others rely
  # on their LSPs or are unformatted. swift-format is additionally skipped
  # because the upstream treefmt-nix module is marked broken.
}

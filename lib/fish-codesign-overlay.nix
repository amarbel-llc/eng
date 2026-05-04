# Workaround for aarch64-darwin codesigning bug (NixOS/nixpkgs#507531,
# NixOS/nixpkgs#208951, NixOS/nix#6065). On Apple Silicon, fish binaries
# from cache.nixos.org occasionally have invalid `linker-signed` ad-hoc
# signatures because nix-daemon's `RewritingSink` rewrites scratch-path
# bytes inside Mach-O pages already covered by SHA-256 page hashes,
# without recomputing them. The kernel SIGKILLs the process at first
# page-in (`cs_invalid_page`).
#
# Setting any cache-busting attribute on `fish` makes its drv hash
# differ from cache.nixos.org's, forcing a local rebuild on this
# machine where no broken sibling state exists, so `ld -adhoc_codesign`
# produces a binary whose CodeDirectory matches its actual page hashes.
#
# Affected build paths:
#   - direnv's `nativeCheckInputs = [ fish ]` runs `fish ./test/direnv-test.fish`
#     in checkPhase; with a broken cached fish, the test SIGKILLs and
#     direnv fails to build (and so does spinclass via mkSpinclass).
#   - The system / home-manager fish (`programs.fish`) is the user's
#     interactive shell; if it has a broken signature, opening a
#     terminal fails.
#
# Remove when NixOS/nix#15638 (or its successor) merges and the daemon
# fixes Mach-O page hashes after the rewrite, or when the architectural
# rework that eliminates `RewritingSink` lands.
_final: prev: {
  fish = prev.fish.overrideAttrs (_old: {
    NIX_FORCE_LOCAL_REBUILD = "darwin-codesign-fix";
  });
}

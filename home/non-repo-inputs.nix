# Inputs excluded from the auto-imported repo package set.
#
# Shared by flake.nix and home/repo-packages.nix — both filter flake
# inputs through this list before auto-importing default packages.
# Inputs without a `.packages.<system>.default` are caught by the
# shape filter and do NOT need to appear here.
#
# keep sorted
[
  "bob"
  "clown"
  "home-manager"
  "moxy"
  "nix-darwin"
  "nix-plist-manager"
  "purse-first"
  "self"
  "tacky"
]

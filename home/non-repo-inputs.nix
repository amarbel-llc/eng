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
  # spinclass is composed manually via lib.mkSpinclass with madder +
  # direnv pinned (see home/repo-packages.nix and flake.nix). Auto-
  # importing packages.default would give us a vanilla build with
  # all integrations dormant — see issue #63.
  "spinclass"
  "tacky"
]

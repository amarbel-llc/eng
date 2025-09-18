targets := "find . -maxdepth 1 -type d ! -name '.*' -print0"

all: update-nix-all build-nix-all

update-nix-all:
  #! /usr/bin/env -S bash
  find . -maxdepth 1 -type d ! -name '.*' -print0 \
    | xargs -0 -L1 just update-nix

update-nix target:
  #! /usr/bin/env -S bash -e
  pushd "{{invocation_directory()}}/{{target}}" >/dev/null
  nix flake update

# TODO doesn't work yet
build-nix target:
  #! /usr/bin/env -S bash -e
  pushd "{{invocation_directory()}}/{{target}}" >/dev/null
  nix build

build-nix-all:
  #! /usr/bin/env -S bash
  find . -maxdepth 1 -type d ! -name '.*' -print0 \
    | xargs -0 -L1 just build-nix

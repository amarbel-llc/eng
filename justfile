all: clean update build

clean-nix:
  nix-store --gc

clean: clean-nix

# TODO find all flake.nix's and run flake update for local flakes
update-nix-local:
  nix flake update

update-nix:
  nix flake update

update: update-nix

build-nix: update-nix-local
  nix build

[working-directory: "rcm"]
build-rcm: build-rcm-hooks-pre-up build-rcm-hooks-post-up
  rcup

[working-directory: "rcm"]
build-rcm-rcrc:
  # TODO
  cp rcrc ~/.rcrc

[working-directory: "rcm/hooks/pre-up"]
build-rcm-hooks-pre-up:
  chmod +x *

[working-directory: "rcm/hooks/post-up"]
build-rcm-hooks-post-up:
  chmod +x *

build: build-nix build-rcm

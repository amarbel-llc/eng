default: build

clean-nix:
  nix-store --gc

clean: clean-nix

update-nix:
  nix flake update

update: update-nix

nix_overrides := shell('''
  nix eval --file flake.nix --json inputs \
    | jq -r '
      [
        to_entries[]
        | select(.value.url | startswith("github:friedenberg/eng"))
        | [
            "--override-input",
            .key,
            (.value.url | sub("github:friedenberg/eng\\?dir="; "path:./"))
        ]
      ] | add | join(" ")
    '
      ''')

build-nix:
  nix build {{nix_overrides}}

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

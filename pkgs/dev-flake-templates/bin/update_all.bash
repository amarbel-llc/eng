#! /bin/bash -xe

all=(
  ./go
  ./java
  ./javascript
  ./latex
  ./lua
  ./nix
  ./node
  ./pandoc
  ./php
  ./python
  ./ruby
  ./rust
  ./rust-toolchain
  ./shell
)

echo "${all[@]}" | tr " " "\n" | xargs -L1 nix flake update

# find . -maxdepth 1 -mindepth 1 -type d ! -iname '.*' -print0 |
#   xargs -0 -L1 nix flake update

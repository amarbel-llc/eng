#! /bin/bash -xe

# TODO make platform agnostic

PATH="/nix/var/nix/profiles/default/bin:$PATH"
PATH="$(pwd)/result/bin:$PATH"
export PATH

. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix flake update
nix build

bin_fish="$(readlink "$(which fish)")"

os="$(uname -s | tr \[:upper:\] \[:lower:\])"
arch="$(arch)"

cp rcm/rcrc ~/.rcrc
printf "DOTFILES_DIRS=\"%s\"" "$(pwd)/rcm" >> ~/.rcrc

function add_one () {
  dir="$1"

  if [[ ! -d "$dir" ]]; then
    return 0
  fi

  printf "TAGS=\"%s\"" "$dir" >> ~/.rcrc
}

add_one "tag-${os}"
add_one "tag-${arch}"
add_one "tag-${os}_${arch}"

"rcup" -f

# sudo bash -c "echo '$bin_fish' >> /etc/shells"
# sudo chsh -s "$bin_fish"

echo "You should run \`exec fish\` to switch to the installed shell" >&2

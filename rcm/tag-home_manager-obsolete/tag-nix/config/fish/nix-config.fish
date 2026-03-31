# Setup Nix
# save existing path and then prepend it to prefer my shit
# set -l pre_path $PATH
# echo "saving pre path: $PATH"
# fenv "source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
# echo "newly added to path: $PATH"
# set PATH $pre_path $PATH
# echo "newly path: $PATH"
set -e NIX_PATH                                                                                                                                                                
__source_if_exists $HOME/.nix-profile/etc/profile.d/nix.fish                                                                                                                   
__source_if_exists /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish                                                                                                 
fish_add_path /nix/var/nix/profiles/default/bin                                                                                                                                
fish_add_path $HOME/.nix-profile/bin

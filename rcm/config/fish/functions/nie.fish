function nie --description 'run $EDITOR after loading a particular dev $flake template on $target'
  # TODO if arg count is 1, try to infer file type by using:
  # file --mime-type $target
  # and then mapping to the appropriate dev flake template
  #
  set -l flake $argv[1]
  set -l target $argv[2]

  # TODO switch to ~/eng
  nix develop "github:friedenberg/dev-flake-templates?dir=$flake" --command $EDITOR $target
end

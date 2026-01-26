
# TODO add support for ssh hosts
complete \
  --command z \
  --no-files \
  --keep-order \
  --arguments "(__z_complete_scripts)"

# function __z_complete_scripts
#   set -l z $HOME/Zettelkasten/
#   $z/1622033013.awk $z/* \
#     | yq --slurp -r '.[] | select(.kind == "script") | (.file | split("/")[-1]) + "\t" + .description'
# end


# Defined in - @ line 1
function vagrant-reset --description 'alias vagrant-reset=vagrant destroy -f; and vagrant up'
	vagrant destroy -f; and vagrant up $argv;
end

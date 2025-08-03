{
  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, nixpkgs-stable }:
    (utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          packages.default = with pkgs; symlinkJoin {
            name = "ssh";

            paths = [
              openssh
              sshfs
              # sshfs-fuse
            ];

            buildInputs = [
              makeWrapper
            ];

            postBuild = ''
              programsWithConfig=(
                scp
                sftp
                ssh
                ssh-copy-id
                sshfs
              )

              for prog in "''${programsWithConfig[@]}"; do
                wrapProgram "$out/bin/$prog" \
                  --add-flags -o \
                  --add-flags 'UserKnownHostsFile=$SSH_HOME/known_hosts' \
                  --add-flags -F \
                  --add-flags '$SSH_HOME/config' \
                  --prefix PATH : $out/bin
              done
            '';
          };
        }
      )
    );
}

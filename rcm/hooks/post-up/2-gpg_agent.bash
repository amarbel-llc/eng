#! /usr/bin/env -S bash -e

fish -c reset-gpg
ssh-agent-mux --restart-service

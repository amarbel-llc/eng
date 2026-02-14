#! /usr/bin/env bats

setup() {
	bats_load_library bats-support
	bats_load_library bats-assert

	# for shellcheck SC2154
	export output
}

function lux_help { # @test
	run lux -h
	assert_success
}

function nix_mcp_server_help { # @test
	run nix-mcp-server -h
	assert_success
}

function pivy_help { # @test
	run pivy -h
	assert_success
}

function ssh_agent_mux_help { # @test
	run ssh-agent-mux -h
	assert_success
}

function zmx_help { # @test
	run zmx -h
	assert_success
}

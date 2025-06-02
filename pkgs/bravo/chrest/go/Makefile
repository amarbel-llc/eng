
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --output-sync=target
# n_prc := $(shell sysctl -n hw.logicalcpu)
# MAKEFLAGS := --jobs=$(n_prc)
timeout := 10
cmd_bats := BATS_TEST_TIMEOUT=$(timeout) bats --tap

ifeq ($(origin .RECIPEPREFIX), undefined)
				$(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
.RECIPEPREFIX = >

.PHONY: build watch exclude graph_dependencies

build: build/chrest;

files_go_cmd := $(shell find cmd -iname '*.go')
files_go_src := $(shell find src -iname '*.go') go.mod go.sum

build/chrest: build/tests_unit.sigil
>mkdir -p build
>eval "$$(direnv hook bash)"
>go build -o $@ $(files_go_cmd)

build/tests_unit.sigil: $(files_go_cmd) $(files_go_cmd) Makefile
>go test ./...

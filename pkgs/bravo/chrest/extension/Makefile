
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

.PHONY: firefox chrome

build: firefox chrome

firefox:
> pushd "$@"
> $(MAKE)

chrome:
> pushd "$@"
> $(MAKE)

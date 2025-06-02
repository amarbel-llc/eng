
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

.PHONY: build local_deploy sign

build: dist.zip

FILE_FIREFOX_SECRET_ISSUER := $(realpath secrets/jwt_issuer)
FILE_FIREFOX_SECRET_SECRET := $(realpath secrets/jwt_secret)

sign: dist.zip
>eval "$$(direnv hook bash)"
>pushd dist/
>npx --no web-ext sign --channel=listed --amo-metadata=amo-metadata.json --api-key="$(shell cat $(FILE_FIREFOX_SECRET_ISSUER))" --api-secret="$(shell cat $(FILE_FIREFOX_SECRET_SECRET))"


dist.zip: dist/manifest.json dist/main.js $(shell find common -type f) amo-metadata.json
>cp amo-metadata.json common/*.png options* dist/
>zip -r "$@" dist

files_js_copy_to_dist := $(shell find src common/src -type f)

dist/main.js: $(files_js_copy_to_dist)
>cp $(files_js_copy_to_dist) dist/
>eval "$$(direnv hook bash)"
>pushd common/
>npx --no -- rollup --config -p "rollup-plugin-consts={browser_type: 'firefox'}" -o "$(abspath $@)"

dist/manifest.json: common/manifest.json manifest.json
>mkdir -p $(dir $@)
>cat $^ | jq -s 'reduce .[] as $$item ({}; . + $$item)' > "$@"

local_deploy: build
>eval "$$(direnv hook bash)"
>npx --no web-ext run -s dist/ --browser-console



# TODO migrate to justfile

DIR_BUILD := build

OPT_NAME := $(shell cat NAME)
OPT_PHONE := $(shell cat PHONE)
OPT_EMAIL := $(shell cat EMAIL)
OPT_GITHUB_URL := $(shell cat GITHUB_URL)
OPT_VERSION := $(shell cat VERSION)

STR_NAME_SNAKE := $(shell cat NAME | tr "[:upper:]" "[:lower:]" | tr " " "_")

JUSTFILE_VARIABLES := \
		"name=$(OPT_NAME)" \
		"email=$(OPT_EMAIL)" \
		"phone=$(OPT_PHONE)" \
		"github_url=$(OPT_GITHUB_URL)" \
		"version=$(OPT_VERSION)"

FILES_DEPS := VERSION Makefile

FILE_OUT_BASE := $(DIR_BUILD)/$(STR_NAME_SNAKE)_resume

.PHONY: all
all: $(FILE_OUT_BASE).html $(FILE_OUT_BASE).txt $(FILE_OUT_BASE).pdf;

$(FILE_OUT_BASE).%: $(DIR_BUILD)/resume.%
	cp '$<' '$@'

$(DIR_BUILD):
	mkdir $(DIR_BUILD)

build/%: % | $(DIR_BUILD)
	cp '$<' '$@'

WHICH_RESUME := resume.md
# WHICH_RESUME := resume-no-columns.md

build/resume.md: $(WHICH_RESUME) | $(DIR_BUILD)
	cp '$<' '$@'

# build/resume.css: style.scss | $(DIR_BUILD)
# 	nix-shell -p sass --run "sass '$<' '$@'"
#
build/%.pdf.html: build/%.md $(FILES_DEPS) | $(DIR_BUILD)
	resume-builder $(JUSTFILE_VARIABLES) html-standalone "$<"
	mv "$<.html" "$@"

build/%.html: build/%.md $(FILES_DEPS) | $(DIR_BUILD)
	resume-builder $(JUSTFILE_VARIABLES) html-embedded "$<"
	mv "$<.html" "$@"
	# cp build/resume.css $(HOME)/eng/site-linen_is_great/public/
	cp $@ $(HOME)/eng2/site-linenisgreat/public/resume.html

build/NAME.txt: Makefile
	figlet -c -fsmslant '$(OPT_NAME)' > '$@'

build/%.txt: build/%.md build/NAME.txt $(FILES_DEPS) | $(DIR_BUILD)
	resume-builder $(JUSTFILE_VARIABLES) txt "$<"
	mv "$<.txt" "$@"

build/%.docx: build/%.md build/NAME.txt $(FILES_DEPS) | $(DIR_BUILD)
	resume-builder $(JUSTFILE_VARIABLES) docx "$<"
	mv "$<.docx" "$@"

build/%.pdf: build/%.pdf.html $(FILES_DEPS) | $(DIR_BUILD)
	html-to-pdf "$<" > "$@"

.PHONY: clean
clean:
	-rm -rf '$(DIR_BUILD)'

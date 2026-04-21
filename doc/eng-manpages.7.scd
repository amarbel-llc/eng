eng-manpages(7)

# NAME

eng-manpages - man page authoring and build practices for amarbel-llc repositories

# DESCRIPTION

This document prescribes how man pages should be authored, formatted, and
built across the *amarbel-llc* GitHub organization.

There are exactly two acceptable patterns:

. *scdoc via Nix* — for all hand-written pages (sections 1, 5, and 7).
. *Go codegen at postInstall* — for section 1 reference pages of CLI
  tools whose command structure is defined in Go code.

Repositories that use hand-written mdoc/roff or pandoc-converted markdown
should migrate to scdoc. Go-generated section 1 pages may remain as-is.

# PRINCIPLES

. Every CLI tool ships man pages.
. Hand-written pages use scdoc source format.
. CLI reference pages (section 1) are auto-generated from Go command
  definitions when the framework supports it.
. Man pages are built by Nix derivations. Not CI, not justfile recipes.
. Source files live in _doc/_ (or _man/_ for legacy layouts being
  migrated).

# SCDOC PATTERN

## When to use

Use scdoc for every man page that a human writes by hand. This includes:

- Section 1 pages for tools without Go codegen support
- Section 5 pages (file formats, configuration)
- Section 7 pages (concepts, conventions, guides)

## File naming

Source files use the convention _name.N.scd_ where _N_ is the man
section number:

- _moxy.1.scd_ — command reference (section 1)
- _moxyfile.5.scd_ — configuration file format (section 5)
- _moxin.7.scd_ — concept documentation (section 7)

## Directory layout

Place scdoc source files in a _doc/_ directory at the repository root:

```
repo/
  doc/
    tool.1.scd
    tool-config.5.scd
    tool-concepts.7.scd
  flake.nix
```

## Reference Nix derivation

The following derivation compiles all scdoc files for a single man
section. Extend it for additional sections as needed.

```
doc = pkgs.stdenvNoCC.mkDerivation {
  pname = "example-doc";
  version = myVersion;
  src = ./doc;
  nativeBuildInputs = [ pkgs.scdoc ];
  dontUnpack = true;
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/share/man/man1
    mkdir -p $out/share/man/man5
    mkdir -p $out/share/man/man7
    for f in $src/*.1.scd; do
      [ -e "$f" ] || continue
      scdoc < "$f" > "$out/share/man/man1/$(basename "$f" .scd)"
    done
    for f in $src/*.5.scd; do
      [ -e "$f" ] || continue
      scdoc < "$f" > "$out/share/man/man5/$(basename "$f" .scd)"
    done
    for f in $src/*.7.scd; do
      [ -e "$f" ] || continue
      scdoc < "$f" > "$out/share/man/man7/$(basename "$f" .scd)"
    done
  '';
};
```

Include the doc derivation in the package's *symlinkJoin* or reference
it directly so that _nix build_ produces man pages alongside binaries.

## scdoc syntax reference

scdoc uses a minimal markup language. The first line must be the page
header in the form _name(N)_. Sections use _# HEADING_. Key formatting:

*Bold text*
	Wrap in asterisks. Used for command names and emphasis.

_Italic text_
	Wrap in underscores. Used for file paths and variable names.

*Inline code*
	Not directly supported. Use bold or italic for inline references.
	Use fenced code blocks for multi-line examples.

*Lists*
	Ordered lists use _. item_. Unordered lists use _- item_.

*Definition lists*
	A term on its own line, followed by an indented (tab) description
	on the next line.

*Code blocks*
	Fenced with triple backticks on their own lines.

*Pitfall:* do not nest inline formatting. A literal asterisk inside
underscores (e.g. _v\*_) will cause a parse error. Either remove the
inner formatting or escape the special character with a backslash.

For the full specification, see *scdoc*(5).

# GO CODEGEN PATTERN

## When to use

Use Go codegen for section 1 reference pages when the CLI tool's
command structure is defined in Go code using a framework that supports
man page generation. This avoids maintaining hand-written pages that
drift from the actual flag and subcommand definitions.

Two frameworks are in use across the organization:

*purse-first command.App*
	Used by: *spinclass*, *madder* (via vendored copy). The _App_
	type provides _GenerateManpages(dir)_ which emits a top-level
	page and per-subcommand pages. Hidden commands are excluded.

*dodder golf/man*
	Used by: *dodder*. Uses a _PageConfig_ struct with
	interface-driven command introspection. Factors roff primitives
	into a reusable _roff.go_ module. Respects _SOURCE_DATE_EPOCH_
	for reproducible builds.

Both produce the same output structure: a top-level _tool.1_ page
listing all commands, and _tool-subcommand.1_ pages with full flag
documentation.

## Nix integration

There are two ways to invoke the codegen at build time:

*Separate gen_man binary*
	Build a _cmd/tool-gen_man_ subpackage that imports the CLI
	definitions and calls the generation function. Run it in
	_postInstall_, then remove it from _$out/bin_:

```
subPackages = [ "cmd/tool" "cmd/tool-gen_man" ];
postInstall = ''
  $out/bin/tool-gen_man $out
  rm $out/bin/tool-gen_man
'';
```

Used by: *madder*, *dodder*.

*Hidden subcommand*
	The main binary includes a hidden _generate-artifacts_ command
	that writes man pages, completions, and other artifacts to a
	given directory:

```
postInstall = ''
  $out/bin/tool generate-artifacts $out
'';
```

Used by: *spinclass*.

## Generated page structure

Both frameworks produce pages with this structure:

*Top-level page* (_tool.1_)
	NAME, SYNOPSIS, DESCRIPTION, COMMANDS (list of subcommands with
	one-line descriptions), SEE ALSO (links to per-command pages).

*Per-subcommand page* (_tool-subcommand.1_)
	NAME, SYNOPSIS (with flags), DESCRIPTION, OPTIONS (as _.TP_
	entries), ALIASES, EXAMPLES, ENVIRONMENT, FILES, SEE ALSO
	(back-reference to top-level page).

# COMBINING PATTERNS

Many repositories need both patterns: Go codegen for section 1 CLI
reference pages, and scdoc for section 5 (configuration) and section 7
(concept) pages.

## Approach

Write section 5 and 7 pages in scdoc and compile them in a separate Nix
derivation (or the same derivation if the build structure allows it).
Let Go codegen handle section 1 pages at _postInstall_ time.

The final package uses *symlinkJoin* or equivalent to merge the codegen
output (under the main package's _share/man/man1/_) with the scdoc
output (under the doc derivation's _share/man/man5/_ and _man7/_).

## Embedding pre-written pages in Go binaries

An alternative for Go projects is to embed scdoc-compiled pages using
_//go:embed_ and install them alongside the generated pages at
_postInstall_ time. This is the pattern used by *spinclass*, which
embeds hand-written section 5 and 7 pages via an _ExtraManpages_ field
and installs them from the same _generate-artifacts_ command.

This works but couples the man page content to the Go binary's build.
The separate scdoc derivation approach is preferred for new repositories.

# CURRENT STATE BY REPOSITORY

The following table summarizes man page practices across each
amarbel-llc repository as of April 2026.

*eng* — SCDOC
	5 pages (all section 7). Source in _doc/\*.7.scd_. Nix derivation
	compiles with scdoc. Gold standard for hand-written pages.

*bob* — SCDOC
	~14 pages across sub-packages (batman, polkadots, lux,
	sandcastle). Source in _packages/\*/doc/\*.scd_. Per-package Nix
	derivations compile with scdoc.

*pa6e* — SCDOC
	1 page (section 1). Source in _doc/pa6e.1.scd_. Nix derivation
	compiles with scdoc.

*moxy* — MDOC (needs migration)
	4 pages (sections 1, 5, 7). Hand-written mdoc in _cmd/moxy/_.
	Nix derivation copies pre-written roff to _share/man/_. Should
	migrate to scdoc in _doc/_.

*clown* — MDOC (needs migration)
	8 pages (sections 1, 5, 7). Hand-written mdoc in _man/_. Nix
	derivation copies pre-written roff. Should migrate to scdoc in
	_doc/_.

*maneater* — MDOC (needs migration)
	2 pages (sections 1, 5). Hand-written mdoc in _cmd/maneater/_.
	Should migrate to scdoc in _doc/_.

*piggy* — ROFF (needs migration)
	1 page (section 1). Hand-written roff in _man/_. Direct copy in
	Nix. Should migrate to scdoc in _doc/_.

*spinclass* — GO CODEGEN + EMBEDDED ROFF
	Section 1 pages generated by _generate-artifacts_ from
	purse-first command.App. Section 5 and 7 pages are hand-written
	roff embedded via _//go:embed_. The embedded pages should migrate
	to scdoc compiled in a separate derivation.

*madder* — GO CODEGEN + PANDOC (needs migration)
	Section 1 pages generated by _madder-gen_man_ from vendored
	purse-first. Section 7 concept pages written as markdown and
	converted via pandoc with sed post-processing. The markdown pages
	should migrate to scdoc.

*dodder* — GO CODEGEN + PANDOC (needs migration)
	Section 1 pages generated by _dodder-gen_man_ from golf/man.
	Section 7 concept pages written as markdown and converted via
	pandoc. The markdown pages should migrate to scdoc.

*chrest* — NONE
	No man pages. Should add scdoc pages for the CLI and
	configuration.

*nebulous* — NONE
	No man pages.

*tommy* — NONE
	No man pages.

# MIGRATION CHECKLIST

## From mdoc/roff to scdoc

For repositories with hand-written mdoc or roff pages:

. Create a _doc/_ directory at the repository root.
. For each existing man page, create a corresponding _.N.scd_ file in
  _doc/_. Translate the roff markup to scdoc format: _.SH_ becomes
  _# HEADING_, _.B_ becomes asterisk-wrapped bold, _.I_ becomes
  underscore-wrapped italic, _.TP_ becomes definition lists (term on
  own line, tab-indented description below).
. Add a Nix derivation that compiles the scdoc files (see reference
  derivation above).
. Include the doc derivation in the package's _symlinkJoin_ or output.
. Remove the old roff source files and the Nix code that copied them.
. Verify with _nix build_ and _man -l result/share/man/manN/page.N_.

## From pandoc markdown to scdoc

For repositories using pandoc-converted markdown (madder, dodder):

. For each _.md_ page in _docs/man.7/_, create a corresponding
  _.7.scd_ file in _doc/_. Translate markdown headings to scdoc
  _# HEADING_, code fences carry over directly, lists use _. item_
  or _- item_ syntax.
. Add or update the Nix derivation to compile scdoc instead of
  running pandoc.
. Remove the pandoc conversion logic from the Go build's
  _postInstall_ and the _man7Src_ parameter.
. Remove the old markdown source files.

## Adding man pages to a repo that has none

For repositories with no existing man pages:

. Create _doc/_ at the repository root.
. Write scdoc source files for the tool's commands, configuration
  files, and concepts.
. Add a Nix derivation that compiles them (see reference derivation).
. Include the derivation in the package output.
. If the tool uses purse-first or golf/man, also wire Go codegen
  for section 1 pages (see Go codegen pattern above).

# SEE ALSO

*eng*(7), *eng-versioning*(7), *scdoc*(5)

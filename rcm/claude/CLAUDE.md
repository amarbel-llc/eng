# General

- if running within a git worktree (such as `.worktrees/<worktree-name>`), do
  not interface with root git directory at all; use worktree exclusively
  - when deciding where to research the repo, agents MUST use the worktree
- use function names that are descriptive-enough to avoid redundant comments
- if git committing fails due to gpg-signing, DO NOT try to commit without a
  signature, instead ask the user to unlock pivy-agent (the SSH agent that also
  serves as the GPG signing agent)
- when debugging or exploring, DO NOT use ad hoc bash scripts or python scripts,
  instead use ad-hoc justfile recipes. mark them with debug or explore groups

# Tools

- **Lux MCP:** The `lux` MCP server provides symbol lookup, type info, go-to
  definition, find references, and incoming call analysis. **Do not use the
  builtin `LSP` tool** (no plugins are installed for it). Use
  `mcp__plugin_lux_lux__resource-read` and
  `mcp__plugin_lux_lux__resource-templates` to access lux. These tools work in
  both the main conversation and subagents.
  - **Find a symbol by name:**
    `lux://lsp/workspace-symbols?uri=file:///any/file.go&query=SymbolName` ---
    always start here before falling back to Grep. Returns the symbol's file and
    position (0-indexed line/character).
  - **Get type info and docs:**
    `lux://lsp/hover?uri=file:///path&line=0&character=0`
  - **Jump to definition:**
    `lux://lsp/definition?uri=file:///path&line=0&character=0`
  - **Find all references:**
    `lux://lsp/references?uri=file:///path&line=0&character=0`
  - **Find callers:**
    `lux://lsp/incoming-calls?uri=file:///path&line=0&character=0`
  - When dispatching subagents, always include in the prompt: "Use
    `mcp__plugin_lux_lux__resource-read` for symbol lookup, type info,
    definitions, and references. Start with
    `lux://lsp/workspace-symbols?uri=file:///any/file.go&query=SymbolName` to
    locate symbols, then `lux://lsp/hover`, `lux://lsp/definition`,
    `lux://lsp/references` for details. Do not use the builtin `LSP` tool."

# Mid-Task Idea Capture

If I instruct you to create a todo, use the `/file-issue` skill. Also use
`/file-issue` when you encounter a blocking issue in one of my repositories
during work --- file it and continue rather than trying to fix it in the current
task. If I give you a GitHub issue to fix, use the `/fix-issue` skill.

## TODO.md Migration

Repos under friedenberg/ and amarbel-llc/ are migrating from `TODO.md` files to
GitHub Issues for task management. When working in a repo that still has a
`TODO.md`, offer to migrate its contents to GitHub Issues and remove the file.

# Environment

- `direnv reload` within Claude sessions NEVER works as expected. If the
  devshell needs to change (new packages, updated flake inputs), ask the user to
  restart the session with a `direnv reload` in between. Do not attempt to run
  `direnv reload` or `direnv allow` from within the session.

# Debugging

- **Signs you are flailing:** you have tried 2+ hypotheses without confirming
  any, you are surprised by a result but immediately jump to the next theory,
  you are reading code 3+ layers deep without checking intermediate assumptions,
  or you are writing fixes before understanding the root cause.
- **When any of those signs appear:** STOP. Summarize what you know, what is
  surprising, and what assumptions remain untested. Present this to the user and
  wait for direction before continuing. Do not chain hypotheses without checking
  in.
- **Verify before declaring "already fixed":** when investigating a bug, check
  edge cases (type aliases, qualified names, primitive wrappers, cross-package
  references) that may not be covered by the obvious code path. Do not conclude
  an issue is resolved until the specific reproduction case passes.
- **Front-load constraints:** before proposing an approach, state what is
  unavailable in the environment (e.g. no glibc-static, no GNOME on Sway) and
  what has already been tried. This avoids wasting cycles on dead-end
  approaches.

# JSON

- use `jq` for parsing `JSON` files, data, or MCP responses. Do not use python
  for this

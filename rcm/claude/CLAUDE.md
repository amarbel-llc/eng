# General

- if running within a git worktree (such as `.worktrees/<worktree-name>`), do
  not interface with root git directory at all; use worktree exclusively
  - when deciding where to research the repo, agents MUST use the worktree
- use function names that are descriptive-enough to avoid redundant comments
- if git committing fails due to gpg-signing, DO NOT try to commit without a
  signature, instead ask the user to unlock the agent

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

If I instruct you to create a todo, follow these instructions:

1.  Create a GitHub issue in the repo the idea belongs to. Use the
    `get-hubbed issue_create` MCP tool. Keep the title concise and the body
    minimal --- just enough context to act on later.
2.  Say "captured" and continue the current task immediately

Do not: create an FDR, research feasibility, estimate effort, discuss
trade-offs, or ask if I want to pursue it now. Just capture and continue.

If the idea is substantial enough for an FDR, note that in the issue body.
Triage happens in a separate session, never mid-task.

## TODO.md Migration

Repos under friedenberg/ and amarbel-llc/ are migrating from `TODO.md` files to
GitHub Issues for task management. When working in a repo that still has a
`TODO.md`, offer to migrate its contents to GitHub Issues and remove the file.

# Debugging

- **Signs you are flailing:** you have tried 2+ hypotheses without confirming
  any, you are surprised by a result but immediately jump to the next theory,
  you are reading code 3+ layers deep without checking intermediate assumptions,
  or you are writing fixes before understanding the root cause.
- **When any of those signs appear:** STOP. Summarize what you know, what is
  surprising, and what assumptions remain untested. Present this to the user and
  wait for direction before continuing. Do not chain hypotheses without checking
  in.

# JSON

- use `jq` for parsing `JSON` files, data, or MCP responses. Do not use python
  for this

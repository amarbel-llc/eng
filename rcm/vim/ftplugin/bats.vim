
" tests have long literals
setlocal wrap textwidth=0 wrapmargin=0
setlocal list listchars=tab:▸\ ,trail:·,nbsp:·

setlocal equalprg=shfmt\ %
let &l:makeprg = "bash -c 'shellcheck -f gcc % && bats --jobs 8 --tap % >&1'"

let &l:comments = "b:#"
let &l:commentstring = "#%s"

"not ok 1 can_output_organize
"TODO-P4 fix issue with lines followed by `# skip` causing processing issues
setlocal efm=%Enot\ ok\ %*\\d\ %m,
"# (from function `assert_output' in file zz-test/test_helper/bats-assert/src/assert_output.bash, line 194,
"#  in test file zz-test/failed_organize.bats, line 59)
setlocal efm+=%Z%.%#\ in\ test\ file\ %f\\,\ line\ %l)
"#   `assert_output "$(cat "$expected_organize")"' failed
"#
"# -- output differs --
"# expected (5 lines):
"#   ---
"#   * ok
"#   ---
"#
"#   - [one/uno] wow
"# actual (2 lines):
"#   Removed etikett 'ok' from zettel 'one/uno'
"#   [one/uno a6afa0a9dd71704237c33136470573f052c9b4d53584f80e1d2d03ed745cab6d] (updated)
"# --
"#
setlocal efm+=%C%.%#

augroup BatsSyntax
  au!
  autocmd Syntax <buffer> setlocal syntax=bash
augroup END

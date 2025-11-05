
" Invisible tabs for Go
setlocal list listchars=tab:\ \ ,trail:·,nbsp:·
" set highlight clear SpellBad

let b:conform=[
      \ "golines",
      \ "--max-len=80",
      \ "--no-chain-split-dots",
      \ "--shorten-comments",
      \ "--base-formatter=gofumpt",
      \ "$FILENAME",
      \ ]

let b:testprg = "$HOME/.vim/ftplugin/go-test.bash %"

" pipes have to be escaped in makeprg
let &l:makeprg = "bash -c '( go vet ./... 2>&1 \\| sed \"s/^vet: //g\" ) && go build -o /dev/null'"

" let &l:errorformat = "%-G === %.,%-G --- %.,%f:%l %m"

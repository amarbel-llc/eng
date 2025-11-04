
" Invisible tabs for Go
setlocal list listchars=tab:\ \ ,trail:·,nbsp:·
" set highlight clear SpellBad

" let &l:equalprg = "$HOME/.vim/ftplugin/go-format.bash %"
let &l:equalprg = 'golines --max-len=80 --no-chain-split-dots --shorten-comments --base-formatter=gofumpt'
let b:testprg = "$HOME/.vim/ftplugin/go-test.bash %"

" pipes have to be escaped in makeprg
let &l:makeprg = "bash -c '( go vet ./... 2>&1 \\| sed \"s/^vet: //g\" ) && go build -o /dev/null'"

" let &l:errorformat = "%-G === %.,%-G --- %.,%f:%l %m"

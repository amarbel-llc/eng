
" Softtabs, 2 spaces
setlocal tabstop=2
setlocal shiftwidth=2
setlocal shiftround
setlocal expandtab

let s:path_bin = fnamemodify(resolve(expand('<sfile>:p')), ':p:h') . "/result/bin/"

let b:conform=[
      \   "shfmt",
      \   "-s",
      \   "-i=2",
      \   "$FILENAME",
      \ ]

let &l:makeprg = s:path_bin."shellcheck -x -f gcc % >&1"

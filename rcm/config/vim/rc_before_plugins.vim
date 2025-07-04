
" https://github.com/vim-pandoc/vim-pandoc-syntax/issues/185
set termguicolors

" Mouse support
" set mouse=a
" set ttymouse=sgr
" set balloonevalterm

" Styled and colored underline support
let &t_AU = "\e[58:5:%dm"
let &t_8u = "\e[58:2:%lu:%lu:%lum"
let &t_Us = "\e[4:2m"
let &t_Cs = "\e[4:3m"
let &t_ds = "\e[4:4m"
let &t_Ds = "\e[4:5m"
let &t_Ce = "\e[4:0m"

" Strikethrough
let &t_Ts = "\e[9m"
let &t_Te = "\e[29m"

" Truecolor support
let &t_8f = "\e[38:2:%lu:%lu:%lum"
let &t_8b = "\e[48:2:%lu:%lu:%lum"
let &t_RF = "\e]10;?\e\\"
let &t_RB = "\e]11;?\e\\"

" Bracketed paste
let &t_BE = "\e[?2004h"
let &t_BD = "\e[?2004l"
let &t_PS = "\e[200~"
let &t_PE = "\e[201~"

" Cursor control
let &t_RC = "\e[?12$p"
let &t_SH = "\e[%d q"
let &t_RS = "\eP$q q\e\\"
let &t_SI = "\e[5 q"
let &t_SR = "\e[3 q"
let &t_EI = "\e[1 q"
let &t_VS = "\e[?12l"

" Focus tracking
let &t_fe = "\e[?1004h"
let &t_fd = "\e[?1004l"
" execute "set <FocusGained>=\<Esc>[I"
" execute "set <FocusLost>=\<Esc>[O"

" Window title
let &t_ST = "\e[22;2t"
let &t_RT = "\e[23;2t"

" vim hardcodes background color erase even if the terminfo file does
" not contain bce. This causes incorrect background rendering when
" using a color theme with a background color in terminals such as
" kitty that do not support background color erase.
let &t_ut=''

set shell=/bin/bash

set mouse=
" set ttymouse=

set cursorline
set signcolumn=yes

" highlight! link CursorLineSign CursorLineNr
" highlight! link DiagnosticError LineNr
" highlight! link DiagnosticSignError CursorLineNr
highlight! link SignColumn LineNr
hi DiagnosticError ctermbg=0
hi DiagnosticWarn ctermbg=0
hi DiagnosticInfo ctermbg=0
hi DiagnosticHint ctermbg=0

" disable background color erase for kitty
let &t_ut=''

set undolevels=100
set scrolloff=2

set ignorecase
set smartcase
set tags=tags;

" Leader
let mapleader = " "
let maplocalleader = "-"

set backspace=2   " Backspace deletes like most programs in insert mode
set nobackup
set nowritebackup
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set history=50
set ruler         " show the cursor position all the time
set showcmd       " display incomplete commands
set incsearch     " do incremental searching
set laststatus=2  " Always display the status line
set autowrite     " Automatically :write before running commands
set wildmode=list:longest,list:full

" Display extra whitespace
set list listchars=tab:▸\ ,trail:·,nbsp:·

" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set shiftround
set expandtab

" Use The Silver Searcher https://github.com/ggreer/the_silver_searcher
if executable('ag')
  " Use Ag over Grep
  set grepprg=ag\ --vimgrep

  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor --hidden -g ""'

  " ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0
endif

" Make it obvious where 80 characters is
set textwidth=80
set colorcolumn=+1

" Numbers
set number
set numberwidth=5

" Switch between the last two files
nnoremap <leader><leader> <c-^>

" Get off my lawn
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>

"let g:rubytest_in_quickfix = 1
let g:rubytest_cmd_test = "bundle exec rake test:unit"

" Run commands that require an interactive shell
nnoremap <Leader>r :RunInInteractiveShell<space>

" Treat <li> and <p> tags like the block tags they are
let g:html_indent_tags = 'li\|p'

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

" Quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" Set spellfile to location that is guaranteed to exist
set spellfile=$HOME/.vim-spell-en.utf-8.add

" Autocomplete with dictionary words when spell check is on
set complete+=kspell

" Always use vertical diffs
set diffopt+=vertical

"folding settings
set foldmethod=indent   "fold based on indent
set foldnestmax=10      "deepest fold is 10 levels
set nofoldenable        "dont fold by default
set foldlevel=1         "this is just what i use

" Tab completion
" will insert tab at beginning of line,
" will use completion if not at beginning
function! InsertTabWrapper()
  let col = col('.') - 1
  if !col || getline('.')[col - 1] !~ '\k'
    return "\<tab>"
  else
    return "\<c-p>"
  endif
endfunction
inoremap <Tab> <c-r>=InsertTabWrapper()<cr>
inoremap <S-Tab> <c-n>


" bind K to grep word under cursor
nnoremap K :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>

set wildmenu
set wildmode=list:longest

" TODO move to init.lua
function! FormatViaEqualsPrg()
  cexpr []
  w

  echom "using equalprg: " . &l:equalprg

  let save_pos = getpos(".")
  normal gg=G
  call setpos(".", save_pos)

  if v:shell_error
    let contents = join(getline(1, '$'), "\n")
    undo
    :cexpr contents
    copen
  else
    w
    ccl
  endif
  " let save_pos = getpos(".")
  " let cmd = $":1,$!{&l:equalprg} {shellescape(expand("%"))}"
  " echom cmd
  " exe cmd
  " " winrestview(win_view)

  " if v:shell_error != 0
  "   " silent! undo
  "   echom "format failed bad"
  " else
  "   " w
  "   echom "wowhello"
  " endif

  " call setpos(".", save_pos)
endfunction

" TODO move to init.lua
function Gf()
  try
    exec "normal! \<c-w>gf"
  catch /E447/
    tabedit <cfile>
  endtry
endfunction

" TODO move to init.lua
function! TestViaTestPrg()
  echo "Running tests..."
  cexpr []
  w

  let contents = system(expandcmd(b:testprg))

  if v:shell_error
    :cexpr contents
    copen
  else
    ccl
    echo "Test succeeded! " . b:testprg
  endif
endfunction

" set up tab labels with tab number, buffer name
function! MyTabLine()
  let s = ''
  for i in range(tabpagenr('$'))
    " select the highlighting
    if i + 1 == tabpagenr()
      let s .= '%#TabLineSel#'
    else
      let s .= '%#TabLine#'
    endif

    " set the tab page number (for mouse clicks)
    let s .= '%' . (i + 1) . 'T'

    " the label is made by MyTabLabel()
    let s .= ' %{MyTabLabel(' . (i + 1) . ')} '
  endfor

  " after the last tab fill with TabLineFill and reset tab page nr
  let s .= '%#TabLineFill#%T'

  " right-align the label to close the current tab page
  "if tabpagenr('$') > 1
  "  let s .= '%=%#TabLine#%999Xclose'
  "endif

  return s
endfunction

function! MyTabLabel(n)
  let buflist = tabpagebuflist(a:n)
  let winnr = tabpagewinnr(a:n)
  let wincount = tabpagewinnr(a:n, '$')
  let path = pathshorten(fnamemodify(bufname(buflist[winnr - 1]), ':~:.'))
  let label = a:n . ': ' . path
  if wincount > 1
    let label .= ' [' . wincount . ']'
  endif
  return label
endfunction

set tabline=%!MyTabLine()

function EditFtplugin()
  execute(":tabedit $HOME/.vim/ftplugin/".&ft.".vim")
endfunction

nnoremap <leader>et :call EditFtplugin()<cr>
nnoremap <leader>ev :tabe $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>
nnoremap <leader>co :copen<cr>
nnoremap <leader>cc :ccl<cr>

set number relativenumber

augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

augroup open-tabs
  au!
  au VimEnter * ++nested if !&diff | tab all | tabfirst | endif
augroup end

" Automatically open, but do not go to (if there are errors) the quickfix /
" location list window, or close it when is has become empty.
"
" Note: Must allow nesting of autocmds to enable any customizations for quickfix
" buffers.
" Note: Normally, :cwindow jumps to the quickfix window if the command opens it
" (but not if it's already open). However, as part of the autocmd, this doesn't
" seem to happen.
augroup quickfix
  autocmd QuickFixCmdPost [^l]* nested cwindow
  autocmd QuickFixCmdPost    l* nested lwindow
augroup END

" Local config
if filereadable($HOME . "/.vimrc.local")
  source ~/.vimrc.local
endif

" make project-specific vimrc files not scary
set secure

" project-specific vimrc files
set exrc

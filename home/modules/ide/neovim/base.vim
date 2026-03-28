" ------------------------------------------------------------------------------------------------------------------------------
" vim configuration
" ------------------------------------------------------------------------------------------------------------------------------
" environment

set nobackup                                                " disable temporary files
set nowritebackup
set backupcopy=yes                                          " webpack watch
set noswapfile                                              " disable swap file generation
set history=200                                             " set history record count (:, search)
set autoread                                                " auto-load when file is modified externally

" don't beep
set novisualbell
set noerrorbells
set tm=300                                                  " set command timeout
set lazyredraw                                              " don't redraw during macro execution for performance

" display
set title                                                   " change the terminal's title
set showcmd                                                 " display input commands for easy viewing
" set cmdheight=2                                           " cmd line height
set updatetime=250
set cursorcolumn                                            " highlight current column
set cursorline                                              " highlight current line

" If using screen, also need 256 colors
if $TERM == "xterm-256color"
  set t_Co=256                                              " enable vim 256 color support
endif
set list                                                    " show special characters
set listchars=tab:>-,trail:-,extends:#,nbsp:~,precedes:<    " show tabs, spaces, trailing spaces

set number                                                  " show absolute line numbers
set relativenumber                                          " show relative line numbers

" syntax highlight
set synmaxcol=200                                           " syntax highlight column limit, no highlighting beyond 200 columns
syntax sync minlines=256                                    " fix syntax highlighting issues controls how Vim synchronizes the syntax state that should apply at a particular point in the text
" syntax on                                                 " syntax highlighting will overrule settings with the defaults
syntax enable                                               " syntax highlighting will keep current color settings.

" edit
filetype plugin indent on                                   " detect file type, equivalent to filetype on, filetype plugin on, filetype indent on http://easwy.com/blog/archives/advanced-vim-skills-filetype-on/
" set scrolljump=10
set nostartofline                                           " keep cursor postion when switching between buffers
set foldmethod=indent                                       " code folding
set nrformats=bin,octal,hex,alpha                           " make ctrl-a, ctrl-x can increase number,alphabets
set foldlevelstart=99                                       " default to unfold code when opening files
setlocal foldlevel=4                                        " set fold level to 4
set showmatch                                               " briefly jump to matching left bracket when inserting right bracket
" set nowrap                                                " disable wrap
set autoindent                                              " set auto alignment
set smartindent                                             " intelligently choose alignment based on above format, useful for C-like languages

" File encode:encode for varied filetype
set helplang=zh
set encoding=utf-8
set fileencodings=utf-8,ucs-bom,cp936,gb18030
  \,big5,euc-jp,euc-kr,latin1

" Set tab to 2 spaces
set shiftwidth=2                                            " set auto indent tab to 2 spaces
set ts=2                                                    " set tab key to 2 spaces
set softtabstop=2                                           " when pressing backspace, if there are 2 spaces before, clear them together
set expandtab                                               " set tab to spaces
retab                                                       " convert all tabs
set hidden                                                  " allow switching buffers without saving
" search
set ignorecase                                              " set search to ignore case
" set hlsearch                                              " highlight search matches
set incsearch                                               " auto-match word position when searching in program
set backspace=2                                             " set backspace key available
set backspace=indent,eol,start                              " allow backspace to delete specific characters

" buffer
set wildmenu wildmode=full                                  " set display buffer match results

" clipboard
" Copy current file path to clipboard
set clipboard=unnamedplus                                   " system clipboard

" WSL: use win32yank.exe for clipboard (check /mnt/c first for Git Bash/WSL2 path)
if executable('win32yank.exe') || executable('/mnt/c/Windows/System32/win32yank.exe')
  let g:clipboard = {
    \   'name': 'win32yank',
    \   'copy': {
    \      '+': 'win32yank.exe -i',
    \      '*': 'win32yank.exe -i',
    \    },
    \   'paste': {
    \      '+': 'win32yank.exe -o --lf',
    \      '*': 'win32yank.exe -o --lf',
    \   },
    \   'cache_enabled': 0,
    \ }
  nmap <Leader>c :call system("win32yank.exe -i --crlf", expand("%:p"))<CR>
  nmap <Leader>cd :call system("win32yank.exe -i --crlf", expand("%:p:h"))<CR>
" Linux with X11: use xclip (skip if Wayland is detected and wl-copy is unavailable)
elseif executable('xclip') && empty($WAYLAND_DISPLAY)
  nmap <Leader>c :call system("xclip -i -selection c", expand("%:p"))<CR>
  nmap <Leader>cd :call system("xclip -i -selection c", expand("%:p:h"))<CR>
" Linux with Wayland: use wl-clipboard (graceful fallback if compositor doesn't support primary selection)
elseif executable('wl-copy')
  let g:clipboard = {
    \   'name': 'wl-clipboard',
    \   'copy': {
    \      '+': 'wl-copy',
    \      '*': 'wl-copy --primary',
    \    },
    \   'paste': {
    \      '+': 'wl-paste',
    \      '*': 'wl-paste --primary',
    \   },
    \   'cache_enabled': 0,
    \ }
  nmap <Leader>c :call system("wl-copy", expand("%:p"))<CR>
  nmap <Leader>cd :call system("wl-copy", expand("%:p:h"))<CR>
" macOS: use pbcopy
else
  set clipboard=unnamed
  nmap <Leader>c :let @+=expand('%:p')<CR>
  nmap <Leader>cd :let @+=expand('%:p:h')<CR>
endif

" Use a blinking upright bar cursor in Insert mode, a blinking block in normal
if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" Set display search count
set shortmess-=S

" Disable mouse
set mouse=


" ------------------------------------- autocmd -------------------------------------
autocmd InsertEnter * :set norelativenumber                                             " no relativenumber in insert mode
autocmd InsertLeave * :set relativenumber                                               " show relativenumber when leave insert mode
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o          " Disable auto comment
" Auto close quick fix window after select item
autocmd FileType qf nnoremap <buffer> <CR> <CR>:cclose<CR>
autocmd VimLeave * let &t_me="\<Esc>]50;CursorShape=1\x7"                               " Fix iterm2 cursor

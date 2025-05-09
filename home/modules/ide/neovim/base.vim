" ------------------------------------------------------------------------------------------------------------------------------
" vim configuration
" ------------------------------------------------------------------------------------------------------------------------------
" environment
set nocompatible                                            " 去掉有关vi一致性模式，避免以前版本的bug和局限

set nobackup                                                " 禁用临时文件
set nowritebackup
set backupcopy=yes                                          " webpack watch
set noswapfile                                              " 禁用生成swap文件
set history=200                                             " 设置历史记录条数(:, search)
set autoread                                                " 文件在外部被修改时自动加载

" don't beep
set novisualbell
set visualbell t_vb=
set noerrorbells
set tm=300                                                  " 设置命令超时时间
set lazyredraw                                              " 在执行宏命令时，不进行显示重绘；在宏命令执行完成后，一次性重绘，以便提高性能
set ttyfast                                                 " Indicates a fast terminal connection

" display
set title                                                   " change the terminal's title
set showcmd                                                 " 将输入的命令显示出来，便于查看当前输入的信息
" set cmdheight=2                                           " cmd line height
set updatetime=250
set cursorcolumn                                            " 列高亮显示
set cursorline                                              " 行高亮显示

" 如果使用screen也需要开256色
if $TERM == "xterm-256color"
  set t_Co=256                                              " 让vim支持256色
endif
set list                                                    " 显示特殊字符
set listchars=tab:>-,trail:-,extends:#,nbsp:~,precedes:<    " 显示tab，空格，末尾空格

set number                                                  " 显示绝对行号
set relativenumber                                          " 显示相对行号

" syntax highlight
set synmaxcol=200                                           " 代码语法高亮的列数，超过200列不再语法高亮
syntax sync minlines=256                                    " 修复语法突出问题 controls how Vim synchronizes the syntax state that should apply at a particular point in the text
" syntax on                                                 " 代码语法高亮 will overrule settings with the defaults
syntax enable                                               " 代码语法高亮 will keep current color settings.

" edit
filetype plugin indent on                                   " 检测文件的类型，相当于执行filetype on, filetype plugin on, filetype indent on http://easwy.com/blog/archives/advanced-vim-skills-filetype-on/
" set scrolljump=10
set nostartofline                                           " keep cursor postion when switching between buffers
set foldmethod=indent                                       " 代码折叠
set nrformats=bin,octal,hex,alpha                           " make ctrl-a, ctrl-x can increase number,alphabets
set foldlevelstart=99                                       " 设置打开文件默认不折叠代码
setlocal foldlevel=4                                        " 设置折叠层数为
set showmatch                                               " 插入右括号时会短暂地跳转到匹配的左括号
" set nowrap                                                " disable wrap
set autoindent                                              " 设置自动对齐
set smartindent                                             " 依据上面的对齐格式，智能的选择对齐方式，对于类似C语言编写上有用

" File encode:encode for varied filetype
set helplang=zh
set encoding=utf-8
set fileencodings=utf-8,ucs-bom,cp936,gb18030
  \,big5,euc-jp,euc-kr,latin1

" 设置tab为2个空格
set shiftwidth=2                                            " 设置自动对齐tab为2个空格
set ts=2                                                    " 设置tab键为2个空格
set softtabstop=2                                           " 在按退格键时，如果前面有2个空格，则会统一清除
set expandtab                                               " 设置tab为空格
retab                                                       " 转换所有的tab
set hidden                                                  " 设置不需要保存就可以切换buffer
" search
set ignorecase                                              " 设置搜索时忽略大小写
" set hlsearch                                              " 高亮显示搜索匹配到的字符串
set incsearch                                               " 在程序中查询一单词，自动匹配单词的位置
set backspace=2                                             " 设置退格键可用
set backspace=indent,eol,start                              " 让backspace能够删除特定字符

" buffer
set wildmenu wildmode=full                                  " 设置显示buffer匹配结果

" clipboard
" 复制当前文件地址到剪切板
set clipboard=unnamedplus                                   " 系统剪切板
nmap <Leader>c :call system("xclip -i -selection c", expand("%:p"))<CR>
nmap <Leader>cd :call system("xclip -i -selection c", expand("%:p:h"))<CR>

" osx
if !executable('xclip')
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

" 设置显示搜索总个数
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

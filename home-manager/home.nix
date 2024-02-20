{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "root";
  home.homeDirectory = "/root";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/root/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Git
  programs.git = {
    enable = true;

    userName = "Sora Liu";
    userEmail = "soraliu.dev@gmail.com";
  };

  # Neovim
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      { plugin = gruvbox; }
      { plugin = coc-nvim; }
    ];
    extraConfig = ''
let mapleader=" "                   " 设置leader键

" buffer 通过索引快速跳转
nnoremap <C-w> :bp<bar>sp<bar>bn<bar>bd<CR>
" nnoremap <Leader>bd :bdelete<CR>
nnoremap <Leader>[ :bp<CR>
nnoremap <Leader>] :bn<CR>
nnoremap <Leader><Left> :bp<CR>
nnoremap <Leader><Right> :bn<CR>
nmap <leader>1 <Plug>AirlineSelectTab1
nmap <leader>2 <Plug>AirlineSelectTab2
nmap <leader>3 <Plug>AirlineSelectTab3
nmap <leader>4 <Plug>AirlineSelectTab4
nmap <leader>5 <Plug>AirlineSelectTab5
nmap <leader>6 <Plug>AirlineSelectTab6
nmap <leader>7 <Plug>AirlineSelectTab7
nmap <leader>8 <Plug>AirlineSelectTab8
nmap <leader>9 <Plug>AirlineSelectTab9
nmap <leader>0 <Plug>AirlineSelectTab0

" file opt
nmap <silent> <C-s> :w<CR>

" run command
autocmd FileType javascript nnoremap <F5> :!node %<CR>

" not to copy to clipboard
vnoremap s "_d

nnoremap <F4> :exec exists('syntax_on') ? 'syn off': 'syn on'<CR>

nmap <silent> j gj
nmap <silent> k gk
vmap <silent> j gj
vmap <silent> k gk
inoremap <special> jk <ESC>
nnoremap <special> <C-t> <C-i>


" ------------------------------------------------------------------------------------------------------------------------------
" vim configuration
" ------------------------------------------------------------------------------------------------------------------------------
" environment
set nocompatible                    " 去掉有关vi一致性模式，避免以前版本的bug和局限

set nobackup                        " 禁用临时文件
set nowritebackup
set backupcopy=yes                  " webpack watch
set noswapfile                      " 禁用生成swap文件

set history=200                     " 设置历史记录条数(:, search)
set autoread                        " 文件在外部被修改时自动加载
" au CursorHold * checktime           " 设置自动加载时机

" don't beep
set novisualbell
set visualbell t_vb=
set noerrorbells
set tm=300                          " 设置命令超时时间

set lazyredraw                      " 在执行宏命令时，不进行显示重绘；在宏命令执行完成后，一次性重绘，以便提高性能
set ttyfast                         " Indicates a fast terminal connection





" display
set title                           " change the terminal's title
set showcmd                         " 将输入的命令显示出来，便于查看当前输入的信息
" set cmdheight=2                   " cmd line height
set updatetime=300
set cursorcolumn                    " 列高亮显示
set cursorline                      " 行高亮显示
" set nocursorline                    " 禁用行高亮显示
" set nocursorcolumn                  " 禁用列高亮显示

" 如果使用screen也需要开256色
" $ vim ~/.screenrc
" $ termcapinfo xterm 'Co#256:AB=\E[48;5;%dm:AF=\E[38;5;%dm'
if $TERM == "xterm-256color"
  set t_Co=256                        " 让vim支持256色
endif
set list                            " 显示特殊字符
set listchars=tab:>-,trail:-,extends:#,nbsp:~,precedes:<    " 显示tab，空格，末尾空格

set number                          " 显示绝对行号
set relativenumber                  " 显示相对行号
autocmd InsertEnter * :set norelativenumber " no relativenumber in insert mode
autocmd InsertLeave * :set relativenumber   " show relativenumber when leave insert mode





" syntax highlight
set synmaxcol=200                   " 代码语法高亮的列数，超过200列不再语法高亮
syntax sync minlines=256            " 修复语法突出问题 controls how Vim synchronizes the syntax state that should apply at a particular point in the text
" syntax on                           " 代码语法高亮 will overrule settings with the defaults
syntax enable                       " 代码语法高亮 will keep current color settings.





" edit
filetype plugin indent on           " 检测文件的类型，相当于执行filetype on, filetype plugin on, filetype indent on http://easwy.com/blog/archives/advanced-vim-skills-filetype-on/
" set scrolljump=10
set nostartofline                   " keep cursor postion when switching between buffers
set foldmethod=indent               " 代码折叠
set nrformats=bin,octal,hex,alpha   " make ctrl-a, ctrl-x can increase number,alphabets
set foldlevelstart=99               " 设置打开文件默认不折叠代码
setlocal foldlevel=4                " 设置折叠层数为
set showmatch                       " 插入右括号时会短暂地跳转到匹配的左括号
" set nowrap                          " disable wrap
set autoindent                      " 设置自动对齐
set smartindent                     " 依据上面的对齐格式，智能的选择对齐方式，对于类似C语言编写上有用
" set cindent                         " 自动缩进，适合js
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o  " 取消自动注释

" File encode:encode for varied filetype
set helplang=zh
set encoding=utf-8
set fileencodings=utf-8,ucs-bom,cp936,gb18030,big5,euc-jp,euc-kr,latin1
set termencoding=utf-8

" 设置tab为2个空格
set shiftwidth=2                    " 设置自动对齐tab为2个空格
set ts=2                            " 设置tab键为2个空格
set softtabstop=2                   " 在按退格键时，如果前面有2个空格，则会统一清除
set expandtab                       " 设置tab为空格
retab                               " 转换所有的tab

set hidden                          " 设置不需要保存就可以切换buffer




" search
set ignorecase                      " 设置搜索时忽略大小写
" set hlsearch                        " 高亮显示搜索匹配到的字符串
set incsearch                       " 在程序中查询一单词，自动匹配单词的位置
set backspace=2                     " 设置退格键可用
set backspace=indent,eol,start      " 让backspace能够删除特定字符




" buffer
set wildmenu wildmode=full          " 设置显示buffer匹配结果




set pastetoggle=<F9>                " 切换到拷贝模式




" clipboard
" 复制当前文件地址到剪切板
set clipboard=unnamedplus               " 系统剪切板
nmap <Leader>c :call system("xclip -i -selection c", expand("%:p"))<CR>
nmap <Leader>cd :call system("xclip -i -selection c", expand("%:p:h"))<CR>

" osx
if !executable('xclip')
  set clipboard=unnamed
  nmap <Leader>c :let @+=expand('%:p')<CR>
  nmap <Leader>cd :let @+=expand('%:p:h')<CR>
endif



" filetype
au BufRead,BufNewFile *.wxml set filetype=xml
au BufRead,BufNewFile *.conf set filetype=nginx



" 修复iterm2光标问题
autocmd VimLeave * let &t_me="\<Esc>]50;CursorShape=1\x7"
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
    '';
  };
}

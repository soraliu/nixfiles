
" ------------------------------------------------------------------------------------------------------------------------------
" preservim/nerdtree
" ------------------------------------------------------------------------------------------------------------------------------
" 将 NERDTree 的窗口设置在 vim 窗口的右侧（默认为左侧）
let NERDTreeWinPos="right"
let NERDTreeWinSize=40
" 当打开 NERDTree 窗口时，自动显示 Bookmarks
let NERDTreeShowBookmarks=1
" 显示行号
let NERDTreeShowLineNumbers=1
" 是否显示隐藏文件
let NERDTreeShowHidden=1
let NERDTreeAutoDeleteBuffer=1
let NERDTreeQuitOnOpen=1
let NERDTreeIgnore=['node_modules$[[dir]]', '\.git$[[dir]]', '\.yarn$[[dir]]']
" 关闭vim时，如果打开的文件除了NERDTree没有其他文件时，它自动关闭，减少多次按:q!
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") &&b:NERDTreeType == "primary") | q | endif
" vim打开文件时自动打开pwd文件夹目录树
" autocmd vimenter * NERDTree
" 设置bookmark
" let g:NERDTreeBookmarksFile='~/.NERDTreeBookmarks'

" map
function! MaximizeToggle()
  if exists("s:maximize_session")
    exec "source " . s:maximize_session
    call delete(s:maximize_session)
    unlet s:maximize_session
    let &hidden=s:maximize_hidden_save
    unlet s:maximize_hidden_save
  else
    let s:maximize_hidden_save = &hidden
    let s:maximize_session = tempname()
    set hidden
    exec "mksession! " . s:maximize_session
    only
  endif
endfunction


noremap <space>ww <C-w>w                                           " 切换窗口
noremap <space>wh <C-w>h                                           " 向左切换窗口
noremap <space>wj <C-w>j                                           " 向下切换窗口
noremap <space>wk <C-w>k                                           " 向上切换窗口
noremap <space>wl <C-w>l                                           " 向右切换窗口
noremap <space>wr <C-w>r                                           " 移动窗口
noremap <space>= <C-w>=                                           " 还原窗口
noremap <space>z <C-w>_                                           " 最大化窗口
noremap <space>wo :call MaximizeToggle()<CR>                           " 最大化窗口
noremap <space>wc :tabc<CR>                                        " 关闭tab窗口
map     <space>we :NERDTreeToggle<CR>                              " F2 切换nerdtree
map     <space>wa :NERDTreeFind<CR>                                " 定位到当前活动的文本
map <space>+ :vertical resize +10<CR>
map <space>- :vertical resize -10<CR>
map <space>w+ :resize +10<CR>
map <space>w- :resize -10<CR>
map <space>ws :vertical resize 50<CR>
map <space>w] gt
map <space>w[ gT




" ------------------------------------------------------------------------------------------------------------------------------
" Xuyuanp/nerdtree-git-plugin
" ------------------------------------------------------------------------------------------------------------------------------
let g:NERDTreeGitStatusIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ "Unknown"   : "?"
    \ }



" ------------------------------------------------------------------------------------------------------------------------------
" preservim/nerdcommenter
" ------------------------------------------------------------------------------------------------------------------------------
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1
" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1
" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'
" Set a language to use its alternate delimiters by default
let g:NERDAltDelims_java = 1
" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }
" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1
" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1
" Enable NERDCommenterToggle to check all selected lines is commented or not 
let g:NERDToggleCheckAllLines = 1

nnoremap <C-_> <Plug>NERDCommenterToggle
vnoremap <C-_> <Plug>NERDCommenterToggle
inoremap  <C-_> <Esc><Plug>NERDCommenterToggle

"
"
" " ------------------------------------------------------------------------------------------------------------------------------
" " ryanoasis/vim-devicons
" " ------------------------------------------------------------------------------------------------------------------------------
" " let g:DevIconsDefaultFolderOpenSymbol = ''
" function! StartifyEntryFormat()
"     return 'WebDevIconsGetFileTypeSymbol(absolute_path) ." ". entry_path'
" endfunction
"
" let g:WebDevIconsUnicodeDecorateFolderNodes = 1
" let g:DevIconsEnableFoldersOpenClose = 1
" let g:DevIconsEnableFolderExtensionPatternMatching = 1
"
" " set rtp+=$HOME/.local/lib/python2.7/site-packages/powerline/bindings/vim/
" " Always show statusline
" " set laststatus=2
"

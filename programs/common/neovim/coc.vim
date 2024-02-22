function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction


let g:coc_global_extensions = [
  \'coc-css',
  \'coc-emoji',
  \'coc-eslint',
  \'coc-git',
  \'coc-html',
  \'coc-json',
  \'coc-lists',
  \'coc-prettier',
  \'coc-pyright',
  \'coc-sh',
  \'coc-snippets',
  \'coc-solidity',
  \'coc-stylelintplus',
  \'coc-svg',
  \'coc-swagger',
  \'coc-tsserver',
  \'coc-word',
  \'coc-yaml',
  \'coc-yank'
\]


inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1):
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" inoremap <silent><expr> <TAB>
"   \ pumvisible() ? "\<C-y>" :
"   \ coc#expandableOrJumpable() ?
"   \ "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
"   \ <SID>check_back_space() ? "\<TAB>" :
"   \ coc#refresh()
"
" inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
"
" inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
"   \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

inoremap <c-u> <c-o>u
inoremap <c-r> <c-o><c-r>

" inoremap <silent><expr> <c-j> "<c-n>"
" inoremap <silent><expr> <c-k> "<c-p>"
inoremap <silent><expr> <C-j>
  \ coc#pum#visible() ? coc#pum#next(1) :
  \ coc#refresh()
imap <silent><expr> <C-k>
  \ coc#pum#visible() ? coc#pum#prev(1) :
  \ coc#refresh()

" navigate diagnostics
nmap <silent> <C-k> <Plug>(coc-diagnostic-prev)
nmap <silent> <C-j> <Plug>(coc-diagnostic-next)

" GoTo code navigation
" nmap <silent> gd <Plug>(coc-definition)
" nmap <silent> gy <Plug>(coc-type-definition)
" nmap <silent> gi <Plug>(coc-implementation)
" nmap <silent> gr <Plug>(coc-references)
nmap <silent> <c-]> <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" support scss
autocmd FileType scss setl iskeyword+=@-@

" coc-lists
command! -nargs=+ -complete=custom,s:GrepArgs Rg exe 'CocList grep '.<q-args>

function! s:GrepArgs(...)
  let list = ['-S', '-smartcase', '-i', '-ignorecase', '-w', '-word',
        \ '-e', '-regex', '-u', '-skip-vcs-ignores', '-t', '-extension']
  return join(list, "\n")
endfunction

" Formatting selected code.
xmap <space><space>f  <Plug>(coc-format-selected)
nmap <space><space>f  <Plug>(coc-format)
" organize imports of the current buffer.
nmap <space><space>o  :call CocAction('runCommand', 'editor.action.organizeImport')<CR>

" Applying codeAction
xmap <space>n  <Plug>(coc-codeaction-selected)
nmap <space>n  <Plug>(coc-codeaction)
nmap <space>l  <Plug>(lsp-code-action)

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> ss <Plug>(coc-range-select)
xmap <silent> ss <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" keymapping
nnoremap <silent> <space>ar :<C-U>call       CocActionAsync('rename')<cr>
" Show all diagnostics.
nnoremap <silent> <space>d :<C-u>CocList --normal diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>e :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent><nowait> <space>m :<C-u>CocList -A commands<cr>
nnoremap <silent><nowait> <space>gh :<C-u>CocCommand git.copyUrl<cr>
nnoremap <silent><nowait> <space>go :<C-u>CocCommand git.browserOpen<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <space>o :<C-u>CocList --normal outline<cr>
" Search workspace symbols.
" nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Keymapping for grep word under cursor with interactive mode
nnoremap <silent> <space>w :exe 'CocList --normal --input='.expand('<cword>').' grep'<CR>
nnoremap <silent><nowait> <space>s :<C-u>CocList grep<cr>
" Resume latest coc list.
nnoremap <silent><nowait> <space>r :<C-u>CocListResume<CR>
" Show yank
nnoremap <silent><nowait> <space>y :<C-u>CocList -A --normal yank<cr>
" float
function FindCursorPopUp()
  let radius = get(a:000, 0, 2)
  let srow = screenrow()
  let scol = screencol()
  " it's necessary to test entire rect, as some popup might be quite small
  for r in range(srow - radius, srow + radius)
    for c in range(scol - radius, scol + radius)
      let winid = popup_locate(r, c)
      if winid != 0
        return winid
      endif
    endfor
  endfor

  return 0
endfunction
function ScrollPopUp(down)
  let winid = FindCursorPopUp()
  if winid == 0
    return 0
  endif

  let pp = popup_getpos(winid)
  call popup_setoptions( winid,
       \ {'firstline' : pp.firstline + ( a:down ? 1 : -1 ) } )

  return 1
endfunction
nnoremap <expr> <Up> ScrollPopUp(0) ? '<esc>' : '<Up>'
nnoremap <expr> <Down> ScrollPopUp(1) ? '<esc>' : '<Down>'

" Use <C-j> for jump to next placeholder, it's default of coc.nvim
let g:coc_snippet_next = '<c-l>'
" Use <C-k> for jump to previous placeholder, it's default of coc.nvim
let g:coc_snippet_prev = '<c-h>'

" coc recommend config
" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
set shortmess+=c
set signcolumn=yes




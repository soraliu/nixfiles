vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
  pattern = { '*.md', '*.json' },
  callback = function()
    vim.cmd('set conceallevel=0')
  end,
})


-- ------------------------------------------------------------------------------------------------------------------------------
-- Configure Neovim statusline
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  'akinsho/bufferline.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    vim.opt.termguicolors = true
    require("bufferline").setup{}
  end,
})


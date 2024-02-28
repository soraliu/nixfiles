
-- ------------------------------------------------------------------------------------------------------------------------------
-- Show a welcome page
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    'goolord/alpha-nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function ()
      require'alpha'.setup(require'alpha.themes.startify'.config)

      vim.keymap.set('n', '<space>t', ":Alpha<CR>")
    end
  }
})


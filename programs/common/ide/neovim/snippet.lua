-- -------------------------------------------------------------------------------------------------------------------------------
-- Lua Snippets
-- -------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    'soraliu/friendly-snippets', -- include common used snippets,
    branch = 'main',
    lazy = true,
  },
  {
    'L3MON4D3/LuaSnip',
    version = 'v2.*', -- Replace <CurrentMajor> by the latest released major (first number of latest release)
    build = 'make install_jsregexp',
    init = function()
      vim.tbl_map(function(type)
        require('luasnip.loaders.from_' .. type).lazy_load()
      end, { 'vscode', 'snipmate', 'lua' })
    end,
  },
})

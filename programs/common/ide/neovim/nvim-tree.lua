-- ------------------------------------------------------------------------------------------------------------------------------
-- Sidebar
-- TODO :h nvim-tree-opts-diagnostics
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  { 'nvim-tree/nvim-web-devicons', lazy = true },
  {
    'nvim-tree/nvim-tree.lua',
    init = function()
      -- disable netrw at the very start of your init.lua
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      -- optionally enable 24-bit colour
      vim.opt.termguicolors = true
    end,
    keys = {
      { '<space>wa', '<cmd>NvimTreeFindFile<cr>', mode = { 'n' }, desc = 'Find File' },
      { '<space>we', '<cmd>NvimTreeToggle<cr>', mode = { 'n' }, desc = 'Toggle Nvim Tree' },
    },
    config = function()
      local function on_attach(bufnr)
        local api = require('nvim-tree.api')

        local function opts(desc)
          return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end
        local function removeMap(lhs)
          vim.keymap.del('n', lhs, { buffer = bufnr })
        end

        -- default mappings
        api.config.mappings.default_on_attach(bufnr)

        -- remove all bookmark shortcut
        removeMap('m')
        removeMap('M')
        removeMap('bd')
        removeMap('bt')
        removeMap('<C-e>')
        removeMap('bmv')

        -- custom mappings
        vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
        vim.keymap.set('n', 'p', api.node.navigate.parent, opts('Parent Directory'))
        vim.keymap.set('n', 'P', api.fs.paste, opts('Paste'))
        vim.keymap.set('n', 'm', api.fs.rename_full, opts('Rename: Full Path'))
      end

      -- OR setup with some options
      require('nvim-tree').setup({
        on_attach = on_attach,
        sort = {
          sorter = 'case_sensitive',
        },
        view = {
          width = 48,
          side = 'right',
        },
        ui = {
          confirm = {
            default_yes = true,
          },
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false,
        },
      })
    end,
  },
})

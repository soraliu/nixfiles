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
      { '<space>we', '<cmd>NvimTreeToggle<cr>',   mode = { 'n' }, desc = 'Toggle Nvim Tree' },
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
        -- <C-o>: preview the file under cursor with mcat in a new herdr tab (md/images/video/pdf...)
        local function open_in_herdr_tab()
          local node = api.tree.get_node_under_cursor()
          if not (node and node.absolute_path) or node.nodes then
            return vim.notify('No valid file under cursor', vim.log.levels.WARN)
          end
          if vim.env.HERDR_ENV ~= '1' then
            return vim.notify('Only available inside herdr', vim.log.levels.WARN)
          end
          -- reuse the existing preview tab with the same label instead of creating a new one
          local label = 'mcat: ' .. vim.fn.fnamemodify(node.absolute_path, ':t')
          local list_ok, tabs = pcall(vim.fn.system, {
            'herdr', 'tab', 'list', '--workspace', vim.env.HERDR_WORKSPACE_ID,
          })
          if list_ok and tabs ~= '' then
            local ok, parsed_list = pcall(vim.json.decode, tabs)
            if ok and parsed_list and parsed_list.result and parsed_list.result.tabs then
              for _, t in ipairs(parsed_list.result.tabs) do
                if t.label == label then
                  vim.fn.jobstart({ 'herdr', 'tab', 'focus', t.tab_id })
                  return
                end
              end
            end
          end
          local ok_create, out = pcall(vim.fn.system, {
            'herdr',
            'tab',
            'create',
            '--workspace',
            vim.env.HERDR_WORKSPACE_ID,
            '--label',
            label,
            '--focus',
          })
          if not ok_create then
            return vim.notify('herdr tab create failed', vim.log.levels.ERROR)
          end
          local ok, parsed = pcall(vim.json.decode, out)
          if not ok or not (parsed and parsed.result and parsed.result.root_pane) then
            return vim.notify('herdr tab create failed', vim.log.levels.ERROR)
          end
          vim.fn.jobstart({
            'herdr',
            'pane',
            'run',
            parsed.result.root_pane.pane_id,
            'mcat ' .. vim.fn.shellescape(node.absolute_path),
          })
        end
        vim.keymap.set('n', '<C-o>', open_in_herdr_tab, opts('Preview in herdr tab (mcat)'))

        local function open_in_finder()
          local node = api.tree.get_node_under_cursor()
          if node and node.absolute_path then
            vim.fn.jobstart({ 'open', '-R', node.absolute_path }, { detach = true })
          else
            vim.notify('No valid file under cursor', vim.log.levels.WARN)
          end
        end
        vim.keymap.set('n', 'r', open_in_finder, { buffer = bufnr, desc = 'Open in Finder' })
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
          git_ignore = false,
        },
      })
    end,
  },
})

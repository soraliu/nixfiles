
-- -------------------------------------------------------------------------------------------------------------------------------
-- LSP
-- -------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {{
  "neovim/nvim-lspconfig",
  lazy = false,
  config = function()
    -- Global mappings.
    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    vim.keymap.set('n', '<space>d', vim.diagnostic.open_float)
    vim.keymap.set('n', '<C-k>', vim.diagnostic.goto_prev)
    vim.keymap.set('n', '<C-j>', vim.diagnostic.goto_next)
    -- vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

    -- Use LspAttach autocommand to only map the following keys
    -- after the language server attaches to the current buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('UserLspConfig', {}),
      callback = function(ev)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf }
        vim.keymap.set('n', '<C-]>', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
        -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
        -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
        -- vim.keymap.set('n', '<space>wl', function()
        --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        -- end, opts)
        vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set({ 'n', 'v' }, '<space>a', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<space>f', function()
          vim.lsp.buf.format { async = true }
        end, opts)
      end,
    })
  end,
  dependencies = {
    {
      "williamboman/mason.nvim",
      config = function()
        require("mason").setup({
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗"
                }
            }
        })
      end,
    }, {
      "williamboman/mason-lspconfig.nvim",
      config = function()
        require("mason-lspconfig").setup({
          ensure_installed = {
            "biome",              -- js, jsx, ts, tsx
            "lua_ls",             -- lua
            "rust_analyzer",      -- rust
            "bashls",             -- bash
            "rnix",               -- nix
            "cmake",              -- Makefile, configure.ac
          },
        })
        require("mason-lspconfig").setup_handlers {
            -- The first entry (without a key) will be the default handler
            -- and will be called for each installed server that doesn't have
            -- a dedicated handler.
            function (server_name) -- default handler (optional)
                require("lspconfig")[server_name].setup {}
            end,
            -- Next, you can provide a dedicated handler for specific servers.
            -- For example, a handler override for the `rust_analyzer`:
            -- ["rust_analyzer"] = function ()
            --     require("rust-tools").setup {}
            -- end
        }
      end,
    }
  },
}, {
  "soraliu/vim-argwrap",
  config = function()
    vim.keymap.set('n', '<space>a', ":ArgWrap<CR>", { silent = true })
  end
}})


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
        local telescopeBuiltin = require('telescope.builtin')
        vim.keymap.set('n', '<C-]>', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gr', telescopeBuiltin.lsp_references, opts)
        vim.keymap.set('n', 'gi', telescopeBuiltin.lsp_implementations, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

        -- TODO: to support auto show function signature

        -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
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

    require'lspconfig'.lua_ls.setup {
      on_init = function(client)
        local path = client.workspace_folders[1].name
        if not vim.loop.fs_stat(path..'/.luarc.json') and not vim.loop.fs_stat(path..'/.luarc.jsonc') then
          client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
            Lua = {
              runtime = {
                -- Tell the language server which version of Lua you're using
                -- (most likely LuaJIT in the case of Neovim)
                version = 'LuaJIT'
              },
              -- Make the server aware of Neovim runtime files
              workspace = {
                checkThirdParty = false,
                library = {
                  vim.env.VIMRUNTIME,
                  -- Depending on the usage, you might want to add additional paths here.
                  -- E.g.: For using `vim.*` functions, add vim.env.VIMRUNTIME/lua.
                  vim.env.VIMRUNTIME/lua,
                  "${3rd}/luv/library",
                  -- "${3rd}/busted/library",
                }
                -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
                -- library = vim.api.nvim_get_runtime_file("", true)
              },
            },
          })
        end
        return true
      end
    }
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
            "tsserver",           -- js, jsx, ts, tsx
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

          -- To support coq_nvim
          -- local coq = require "coq"
          -- function (server_name) -- default handler (optional)
          --     require("lspconfig")[server_name].setup(coq.lsp_ensure_capabilities {})
          -- end,


          -- Next, you can provide a dedicated handler for specific servers.
          -- For example, a handler override for the `rust_analyzer`:
          -- ["rust_analyzer"] = function ()
          --     require("rust-tools").setup {}
          -- end
        }
      end,
    },
    {
      'hrsh7th/nvim-cmp',
      dependencies = {
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-cmdline',
        'windwp/nvim-autopairs', -- insert `(` after select function or method item
        {
          "L3MON4D3/LuaSnip",
          -- follow latest release.
          version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
          -- install jsregexp (optional!).
          build = "make install_jsregexp"
        },
      },
      config = function()
        -- Set up nvim-cmp.
        local cmp_status_ok, cmp = pcall(require, "cmp")
        if not cmp_status_ok then
          return
        end

        -- add `()` after the choosed function in lsp completion
        local cmp_autopairs = require('nvim-autopairs.completion.cmp')
        cmp.event:on(
          'confirm_done',
          cmp_autopairs.on_confirm_done()
        )

        -- luasnip
        local snip_status_ok, luasnip = pcall(require, "luasnip")
        if not snip_status_ok then
          return
        end
        require("luasnip/loaders/from_vscode").lazy_load()

        cmp.setup({
          snippet = {
            -- REQUIRED - you must specify a snippet engine
            expand = function(args)
              -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
              luasnip.lsp_expand(args.body) -- For `luasnip` users.
              -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
              -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
            end,
          },
          window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered(),
          },
          mapping = cmp.mapping.preset.insert({
            ['<C-u>'] = cmp.mapping.scroll_docs(-4),
            ['<C-d>'] = cmp.mapping.scroll_docs(4),
            ['<C-j>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              else
                cmp.complete()
              end
            end, { "i", "s" }),
            ['<C-k>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              else
                cmp.complete()
              end
            end, { "i", "s" }),
            ['<C-e>'] = cmp.mapping.abort(),
            -- ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
            ["<CR>"] = cmp.mapping.confirm({
              behavior = cmp.ConfirmBehavior.Replace,
              select = true,
            }),
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { "i", "s" }),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),
          }),
          sources = cmp.config.sources({
            { name = 'nvim_lsp' },
            { name = 'path' },
            { name = 'nvim_lua' },
            -- { name = 'vsnip' }, -- For vsnip users.
            { name = 'luasnip' }, -- For luasnip users.
            -- { name = 'ultisnips' }, -- For ultisnips users.
            -- { name = 'snippy' }, -- For snippy users.
          }, {
            { name = 'buffer' },
          })
        })
      end,
    },
    {
      -- Note: To make it work with Nix, should update the env of nvim-python to fix the issue of `can't find coq module`
      -- 1. run `:checkhealth provider`
      -- 2. edit the file of the value of `g:python3_host_prog`, e.g. `vi /nix/store/wb8ql9px3dn5j63k0nhnxlv1zzy0bcj4-neovim-0.9.4/bin/nvim-python3`
      -- 3. add `export PYTHONPATH="/root/.local/share/nvim/lazy/coq_nvim"` below the `unset PYTHONPATH`
      -- 4. force save the change

      -- uncomment the following codes to use `coq_nvim`
      -- "ms-jpq/coq_nvim",
      -- branch = "coq",
      -- dependencies = {
      --   "ms-jpq/coq.artifacts",
      --   branch = "artifacts"
      -- },
      -- config = function()
      -- end,
    }
  },
}})


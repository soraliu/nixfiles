
-- ------------------------------------------------------------------------------------------------------------------------------
-- Syntax
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function () 
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        ensure_installed = {
          "c",
          "lua",

          -- Editor
          "vim",
          "vimdoc",

          -- Conf
          "json",
          "jsonc",
          "yaml",
          "xml",

          -- DevOps
          "nix",

          -- FE
          "html",
          "css",
          "scss",
          "jsdoc",
          "javascript",
          "typescript",
          "vue",
        },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "]]", -- set to `false` to disable one of the mappings
            node_incremental = "}",
            scope_incremental = "]]",
            node_decremental = "{",
          },
        },
      })

      vim.cmd([[
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
        set nofoldenable                     " Disable folding at startup.
      ]])
    end,
})


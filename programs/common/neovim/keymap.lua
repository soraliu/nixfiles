
-- ------------------------------------------------------------------------------------------------------------------------------
-- Show keymaps
-- ------------------------------------------------------------------------------------------------------------------------------

function keysRegisterSearch()
  local wk = require("which-key")
  local builtin = require('telescope.builtin')

  wk.register({
    f = {
      name = "Fuzzy Search", -- optional group name

      -- Editor
      p = { "<cmd>Telescope<cr>",                                           "Telescope Home" },
      l = { function() builtin.git_files({ show_untracked = true }) end,    "Find Files" },
      o = { function() builtin.oldfiles({ cwd_only = true }) end,           "Find Recent Files" },
      b = { builtin.buffers,                                                "Find Opened Buffers" },
      w = { builtin.grep_string,                                            "Grep Cursor Word" },
      k = { builtin.keymaps,                                                "Find Keymaps" },
      h = { builtin.help_tags,                                              "Find Helps" },
      m = { builtin.commands,                                               "Find Commands" },
      s = { "<cmd>Telescope egrepify<cr>",                                  "Grep String" },

      -- LSP
      m = { builtin.diagnostics,                                            "LSP Diagnostics" },
      m = { builtin.lsp_references,                                         "LSP References" },
      i = { builtin.lsp_implementations,                                    "LSP Implementations" },
    },
  }, { prefix = "<leader>" })
end

function keysRegisterTelescope()
  -- :h telescope.mappings
  return {
    i = {
      ["<c-j>"] = "move_selection_next",
      ["<c-k>"] = "move_selection_previous",
      ["<esc>"] = "close",
   },
  }
end

function keysRegisterClearMem()
end

table.insert(plugins, {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300

      keysRegisterSearch()
    end,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  },
})

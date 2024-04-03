-- ------------------------------------------------------------------------------------------------------------------------------
-- Marks
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    "cbochs/grapple.nvim",
    dependencies = {
      { "nvim-tree/nvim-web-devicons", lazy = true }
    },
    opts = {
      scope = "git", -- also try out "git_branch"
    },
    event = { "BufReadPost", "BufNewFile" },
    cmd = "Grapple",
    config = function()
      require("grapple").setup()

      keysRegisterMarks()
    end,
  }
})

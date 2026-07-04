return {
  { "folke/persistence.nvim", enabled = false },

  {
    "olimorris/persisted.nvim",
    lazy = false,
    priority = 1000,
    dependencies = { "nvim-telescope/telescope.nvim" },
    init = function()
      vim.o.sessionoptions = "buffers,curdir,folds,globals,tabpages,winpos,winsize"
    end,
    opts = {
      autosave = true,
      autoload = true,
      use_git_branch = true,
      follow_cwd = true,
      silent = true,
      ignored_dirs = {
        vim.fn.expand("~"),
        "/tmp",
      },
    },
    config = function(_, opts)
      require("persisted").setup(opts)
      require("telescope").load_extension("persisted")
    end,
    keys = {
      { "<leader>qs", "<cmd>SessionLoad<cr>", desc = "Load session for cwd" },
      { "<leader>ql", "<cmd>SessionLoadLast<cr>", desc = "Load last session" },
      { "<leader>qd", "<cmd>SessionDelete<cr>", desc = "Delete current session" },
      { "<leader>qS", "<cmd>Telescope persisted<cr>", desc = "List sessions" },
    },
  },
}

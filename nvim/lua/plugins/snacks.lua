return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  -- Fix the dashboard terminal section (pokemon-colorscripts) on nvim 0.12:
  --  * nvim 0.12 draws "[Process exited 0]" as an extmark (virtual text) instead
  --    of a buffer line, so snacks' own hide_process_exited() no longer catches it.
  --  * the term buffer is started in a hidden window that inherits the global
  --    number/relativenumber, and those come back when snacks swaps it into the
  --    float -> line numbers on the left.
  init = function()
    local exitmsg_ns = vim.api.nvim_create_namespace("nvim.terminal.exitmsg")
    local group = vim.api.nvim_create_augroup("snacks_dashboard_term", { clear = true })

    local function clean(buf)
      if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "snacks_dashboard" then
        return
      end
      vim.api.nvim_buf_clear_namespace(buf, exitmsg_ns, 0, -1)
      -- the dashboard is a static screen: ignore the mouse wheel so it never scrolls
      for _, dir in ipairs({ "Up", "Down", "Left", "Right" }) do
        for _, mod in ipairs({ "", "S-", "C-", "A-" }) do
          vim.keymap.set({ "n", "v" }, ("<%sScrollWheel%s>"):format(mod, dir), "<Nop>", { buffer = buf, silent = true })
        end
      end
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        for opt, val in pairs({
          number = false,
          relativenumber = false,
          signcolumn = "no",
          foldcolumn = "0",
          statuscolumn = "",
          cursorline = false,
        }) do
          vim.wo[win][0][opt] = val
        end
      end
    end

    vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
      group = group,
      callback = function(ev)
        clean(ev.buf)
      end,
    })
    -- the main dashboard buffer gets its filetype without firing FileType
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "SnacksDashboardOpened",
      callback = function()
        clean(vim.api.nvim_get_current_buf())
      end,
    })
    -- the exit message is set on TermClose, which can fire after FileType
    vim.api.nvim_create_autocmd("TermClose", {
      group = group,
      callback = function(ev)
        vim.defer_fn(function()
          clean(ev.buf)
        end, 50)
      end,
    })
  end,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = {
      width = 60,
      row = nil,                                                                   -- dashboard position. nil for center
      col = nil,                                                                   -- dashboard position. nil for center
      pane_gap = 4,                                                                -- empty columns between vertical panes
      autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- autokey sequence
      -- These settings are used by some built-in sections
      preset = {
        -- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
        ---@type fun(cmd:string, opts:table)|nil
        pick = nil,
        -- Used by the `keys` section to show keymaps.
        -- Set your custom keymaps here.
        -- When using a function, the `items` argument are the default keymaps.
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = "", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          {
            icon = " ",
            key = "r",
            desc = "Recent Files",
            action = ":lua Snacks.dashboard.pick('oldfiles')",
          },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          {
            icon = "󰒲 ",
            key = "L",
            desc = "Lazy",
            action = ":Lazy",
            enabled = package.loaded.lazy ~= nil,
          },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
        -- Used by the `header` section
        header = [[
███╗   ██╗ █████╗ ███╗   ███╗██████╗ ███╗   ██╗ ██████╗  ██████╗  █████╗
████╗  ██║██╔══██╗████╗ ████║██╔══██╗████╗  ██║██╔════╝ ██╔═████╗██╔══██╗
██╔██╗ ██║███████║██╔████╔██║██║  ██║██╔██╗ ██║██║  ███╗██║██╔██║╚██████║
██║╚██╗██║██╔══██║██║╚██╔╝██║██║  ██║██║╚██╗██║██║   ██║████╔╝██║ ╚═══██║
██║ ╚████║██║  ██║██║ ╚═╝ ██║██████╔╝██║ ╚████║╚██████╔╝╚██████╔╝ █████╔╝
╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝  ╚════╝
                                                                         ]],
      },
      sections = {
        { section = "header" },
        { section = "keys",   gap = 1, padding = 1 },
        { section = "startup" },
        {
          section = "terminal",
          cmd = "fish -c 'pokemon-colorscripts -r --no-title; sleep .1'",
          random = 10,
          pane = 2,
          indent = 4,
          height = 20,
        },
      },
    },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    picker = {
      enabled = true,
      sources = {
        formatter = {
          file = {
            filename_first = true,
          },
        },
      },
    },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    styles = {
      notification = {
        -- wo = { wrap = true } -- Wrap notifications
      },
    },
  },
  keys = {
    -- Fuzzy find
    {
      "<leader>fm",
      function()
        Snacks.picker.smart()
      end,
      desc = "Smart Find Files",
    },
    {
      "<leader>ff",
      function()
        Snacks.picker.files({
          args = {
            "--no-ignore",
            "--no-ignore-vcs",
            "--hidden",

            -- Exclude folders
            "--exclude", "node_modules",
            "--exclude", "target",
            "--exclude", "dist", }
        })
      end,
      desc = "Fuzzy find files",
    },
    {
      "<leader>fs",
      function()
        Snacks.picker.grep({
          args = {
            "--no-ignore",
            "--no-ignore-vcs",
            "--hidden",

            -- Exclude common folders
            "--glob", "!node_modules/**",
            "--glob", "!target/**",
            "--glob", "!dist/**",

            -- Flutter & platform folders exclude
            "--glob", "!android/**",
            "--glob", "!.dart_tool/**",
            "--glob", "!.idea/**",
            "--glob", "!build/**",
            "--glob", "!ios/**",
            "--glob", "!macos/**",
            "--glob", "!web/**",
            "--glob", "!windows/**",
            "--glob", "!linux/**",
            "--glob", "!.next/**",
            "--glob", "!__MACOSX/**",
          },
        })
      end,
      desc = "Grep",
    },
    {
      "<leader>fb",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Buffers",
    },
    {
      "<leader>bd",
      function()
        Snacks.bufdelete()
      end,
      desc = "Delete Buffer",
    },
    {
      "<leader>fc",
      function()
        Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "Find Config File",
    },
    -- git
    {
      "<leader>gb",
      function()
        Snacks.picker.git_branches()
      end,
      desc = "Git Branches",
    },
    {
      "<leader>gB",
      function()
        Snacks.git.blame_line()
      end,
      desc = "Git Blame",
    },
    {
      "<leader>gl",
      function()
        Snacks.picker.git_log()
      end,
      desc = "Git Log",
    },
    {
      "<leader>gL",
      function()
        Snacks.picker.git_log_line()
      end,
      desc = "Git Log Line",
    },
    {
      "<leader>gs",
      function()
        Snacks.picker.git_status()
      end,
      desc = "Git Status",
    },
    {
      "<leader>gS",
      function()
        Snacks.picker.git_stash()
      end,
      desc = "Git Stash",
    },
    {
      "<leader>gd",
      function()
        Snacks.picker.git_diff()
      end,
      desc = "Git Diff (Hunks)",
    },
    {
      "<leader>gf",
      function()
        Snacks.picker.git_log_file()
      end,
      desc = "Git Log File",
    },
    -- search
    {
      "<leader>cl",
      function()
        Snacks.picker.colorschemes()
      end,
      desc = "Colorschemes",
    },
    -- Lazy git
    {
      "<leader>lg",
      function()
        Snacks.lazygit()
      end,
      desc = "Lazygit",
    },
    -- Explorer
    {
      "<leader>ee",
      function()
        Snacks.explorer({
          finder = "explorer",
          sort = { fields = { "sort" } },
          supports_live = true,
          tree = true,
          watch = true,
          diagnostics = true,
          diagnostics_open = false,
          git_status = true,
          git_status_open = false,
          git_untracked = true,
          follow_file = true,
          focus = "list",
          auto_close = false,
          jump = { close = false },
          layout = { preset = "sidebar", preview = false },
          -- to show the explorer to the right, add the below to
          -- your config under `opts.picker.sources.explorer`
          -- layout = { layout = { position = "right" } },
          formatters = {
            file = { filename_only = true },
            severity = { pos = "right" },
          },
          matcher = { sort_empty = false, fuzzy = false },
          config = function(opts)
            return require("snacks.picker.source.explorer").setup(opts)
          end,
          win = {
            list = {
              keys = {
                ["<BS>"] = "explorer_up",
                ["l"] = "confirm",
                ["h"] = "explorer_close", -- close directory
                ["a"] = "explorer_add",
                ["d"] = "explorer_del",
                ["r"] = "explorer_rename",
                ["c"] = "explorer_copy",
                ["m"] = "explorer_move",
                ["o"] = "explorer_open", -- open with system application
                ["P"] = "toggle_preview",
                ["y"] = { "explorer_yank", mode = { "n", "x" } },
                ["p"] = "explorer_paste",
                ["u"] = "explorer_update",
                ["<c-c>"] = "tcd",
                ["<leader>/"] = "picker_grep",
                ["<c-t>"] = "terminal",
                ["."] = "explorer_focus",
                ["I"] = "toggle_ignored",
                ["H"] = "toggle_hidden",
                ["Z"] = "explorer_close_all",
                ["]g"] = "explorer_git_next",
                ["[g"] = "explorer_git_prev",
                ["]d"] = "explorer_diagnostic_next",
                ["[d"] = "explorer_diagnostic_prev",
                ["]w"] = "explorer_warn_next",
                ["[w"] = "explorer_warn_prev",
                ["]e"] = "explorer_error_next",
                ["[e"] = "explorer_error_prev",
              },
            },
          },
        })
      end,
      desc = "File Explorer",
    },
    -- Other
    {
      "<leader>z",
      function()
        Snacks.zen()
      end,
      desc = "Toggle Zen Mode",
    },
    {
      "<leader>Z",
      function()
        Snacks.zen.zoom()
      end,
      desc = "Toggle Zoom",
    },
    {
      "<leader>bd",
      function()
        Snacks.bufdelete()
      end,
      desc = "Delete Buffer",
    },
    {
      "<leader>cw",
      function()
        Snacks.toggle.option("wrap")
      end,
      desc = "Wrap Code",
    },
  },
}

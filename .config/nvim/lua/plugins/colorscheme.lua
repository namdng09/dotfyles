return {
  {
    "f-person/auto-dark-mode.nvim",
    priority = 1000,
    init = function()
      vim.cmd.colorscheme "catppuccin"
    end,
    opts = {
      update_interval = 1000,
      set_dark_mode = function()
        vim.api.nvim_set_option_value("background", "dark", { scope = "global" })
      end,
      set_light_mode = function()
        vim.api.nvim_set_option_value("background", "light", { scope = "global" })
      end,
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "auto",
      background = {
        light = 'latte',
        dark = 'mocha',
      },
      no_italic = false,    -- Force no italic
      no_bold = false,      -- Force no bold
      no_underline = false, -- Force no underline
      styles = {            -- Handles the styles of general hi groups (see :h highlight-args):
        comments = { "italic" },
        conditionals = { "italic" },
        loops = { "bold" },
        functions = { "italic", "bold" },
        keywords = { "bold" },
        strings = {},
        variables = {},
        numbers = { "bold" },
        booleans = { "bold", "italic" },
        properties = { "italic" },
        types = { "underline" },
        operators = { "bold" },
        -- miscs = {}, -- Uncomment to turn off hard-coded styles
      },
      custom_highlights = function(colors)
        return {
          Folded = { bg = colors.none },
          UfoFoldedEllipsis = { fg = colors.blue, bg = colors.none },
        }
      end,
      integrations = {
        mason = true,
        noice = true,
        harpoon = true,
        cmp = true,
        lsp_trouble = true,
        which_key = true,
        markdown = true,
        render_markdown = true,
      }
    },
  },
}

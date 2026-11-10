local function follow_or_create_link()
  local obsidian = require("obsidian")
  local util = obsidian.util

  if not util.cursor_on_markdown_link(nil, nil, true, true) then
    return "gf"
  end

  local client = obsidian.get_client()
  local search = obsidian.search
  local Path = obsidian.Path

  client:resolve_link_async(nil, function(...)
    local results = { ... }

    if #results == 0 then
      return
    end

    vim.schedule(function()
      if #results > 1 then
        client:follow_link_async(nil)
        return
      end

      local res = results[1]

      if res.url ~= nil or res.note ~= nil or res.path ~= nil then
        client:follow_link_async(nil)
        return
      end

      if res.link_type == search.RefTypes.Wiki or res.link_type == search.RefTypes.WikiWithAlias then
        local id
        local aliases = {}

        if res.name ~= res.location then
          id = res.location
          aliases = { res.name }
        end

        local note = client:create_note({ title = res.name, id = id, aliases = aliases })
        client:open_note(note)
        return
      end

      if res.link_type == search.RefTypes.Markdown then
        local path = Path.new(res.location)

        if path.suffix == nil then
          path = path:with_suffix(".md")
        end

        if not path:is_absolute() then
          local current_file = vim.api.nvim_buf_get_name(0)
          local base_dir = current_file ~= "" and Path.buffer(0):parent() or Path.cwd()
          path = base_dir / path
        end

        if not path:exists() then
          local parent = path:parent()

          if parent ~= nil then
            parent:mkdir({ parents = true, exist_ok = true })
          end

          path:touch()
        end

        client:open_note(path)
        return
      end

      client:follow_link_async(nil)
    end)
  end)

  return "<Ignore>"
end

return {
  "epwalsh/obsidian.nvim",
  version = "*",  -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre path/to/my-vault/*.md",
  --   "BufNewFile path/to/my-vault/*.md",
  -- },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
  },
  opts = {
    workspaces = {
      {
        name = "notes",
        path = "~/Obsidian Vault",
      },
  },
   mappings = {
    -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
    ["gf"] = {
      action = function()
        return follow_or_create_link()
      end,
      opts = { noremap = false, expr = true, buffer = true },
    },
    -- Toggle check-boxes.
    ["<leader>ch"] = {
      action = function()
        return require("obsidian").util.toggle_checkbox()
      end,
      opts = { buffer = true },
    },
    -- Smart action depending on context, either follow link or toggle checkbox.
    ["<cr>"] = {
      action = function()
        return require("obsidian").util.smart_action()
      end,
      opts = { buffer = true, expr = true },
    }
  },
},
ui = {
    enable = true,  -- set to false to disable all additional syntax features
    update_debounce = 200,  -- update delay after a text change (in milliseconds)
    max_file_length = 5000,  -- disable UI features for files with more than this many lines
    -- Define how various check-boxes are displayed
    checkboxes = {
      -- NOTE: the 'char' value has to be a single character, and the highlight groups are defined below.
      [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
      ["x"] = { char = "", hl_group = "ObsidianDone" },
      [">"] = { char = "", hl_group = "ObsidianRightArrow" },
      ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
      ["!"] = { char = "", hl_group = "ObsidianImportant" },
      -- Replace the above with this if you don't have a patched font:
      -- [" "] = { char = "☐", hl_group = "ObsidianTodo" },
      -- ["x"] = { char = "✔", hl_group = "ObsidianDone" },

      -- You can also add more custom ones...
    },
    -- Use bullet marks for non-checkbox lists.
    bullets = { char = "•", hl_group = "ObsidianBullet" },
    external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
    -- Replace the above with this if you don't have a patched font:
    -- external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
    reference_text = { hl_group = "ObsidianRefText" },
    highlight_text = { hl_group = "ObsidianHighlightText" },
    tags = { hl_group = "ObsidianTag" },
    block_ids = { hl_group = "ObsidianBlockID" },
    hl_groups = {
      -- The options are passed directly to `vim.api.nvim_set_hl()`. See `:help nvim_set_hl`.
      ObsidianTodo = { bold = true, fg = "#f78c6c" },
      ObsidianDone = { bold = true, fg = "#89ddff" },
      ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
      ObsidianTilde = { bold = true, fg = "#ff5370" },
      ObsidianImportant = { bold = true, fg = "#d73128" },
      ObsidianBullet = { bold = true, fg = "#89ddff" },
      ObsidianRefText = { underline = true, fg = "#c792ea" },
      ObsidianExtLinkIcon = { fg = "#c792ea" },
      ObsidianTag = { italic = true, fg = "#89ddff" },
      ObsidianBlockID = { italic = true, fg = "#89ddff" },
      ObsidianHighlightText = { bg = "#75662e" },
    },
  },
}

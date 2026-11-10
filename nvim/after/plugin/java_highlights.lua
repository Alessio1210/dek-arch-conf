-- Darcula-inspired Java colors.  The groups are language-qualified, so this
-- palette never changes highlighting in non-Java buffers.
local java_highlights = {
  ["@comment.java"] = { fg = "#808080", italic = true },
  ["@keyword.java"] = { fg = "#CC7832" },
  ["@keyword.modifier.java"] = { fg = "#CC7832" },
  ["@keyword.exception.java"] = { fg = "#CC7832" },
  ["@keyword.return.java"] = { fg = "#CC7832" },
  ["@keyword.repeat.java"] = { fg = "#CC7832" },
  ["@boolean.java"] = { fg = "#CC7832" },
  ["@type.java"] = { fg = "#A9B7C6" },
  ["@type.builtin.java"] = { fg = "#A9B7C6" },
  ["@constructor.java"] = { fg = "#FFC66D" },
  ["@function.java"] = { fg = "#FFC66D" },
  ["@function.call.java"] = { fg = "#FFC66D" },
  ["@function.method.java"] = { fg = "#FFC66D" },
  ["@function.method.call.java"] = { fg = "#FFC66D" },
  ["@variable.member.java"] = { fg = "#9876AA" },
  ["@property.java"] = { fg = "#9876AA" },
  ["@constant.java"] = { fg = "#9876AA" },
  ["@string.java"] = { fg = "#6A8759" },
  ["@string.escape.java"] = { fg = "#CC7832" },
  ["@character.java"] = { fg = "#6A8759" },
  ["@number.java"] = { fg = "#6897BB" },
  ["@annotation.java"] = { fg = "#BBB529" },
  ["@attribute.java"] = { fg = "#BBB529" },
  ["@attribute.spring.java"] = { fg = "#FFB86C", bold = true },
  ["@label.java"] = { fg = "#CC7832" },
  ["@lsp.type.class.java"] = { fg = "#A9B7C6" },
  ["@lsp.type.interface.java"] = { fg = "#A9B7C6" },
  ["@lsp.type.enum.java"] = { fg = "#A9B7C6" },
  ["@lsp.type.method.java"] = { fg = "#FFC66D" },
  ["@lsp.type.property.java"] = { fg = "#9876AA" },
  ["@lsp.type.parameter.java"] = { fg = "#A9B7C6" },
}

local function apply_java_highlights()
  for group, spec in pairs(java_highlights) do
    vim.api.nvim_set_hl(0, group, spec)
  end
end

local function start_java_treesitter(bufnr)
  local ok, err = pcall(vim.treesitter.start, bufnr, "java")
  if not ok then
    vim.notify("Java Treesitter highlighting could not start: " .. err, vim.log.levels.WARN)
  end
end

apply_java_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("SalarJavaHighlights", { clear = true }),
  callback = apply_java_highlights,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("SalarJavaTreesitter", { clear = true }),
  pattern = "java",
  callback = function(args)
    start_java_treesitter(args.buf)
  end,
})

-- Covers a Java file passed on Neovim's command line before this runtime file
-- is sourced.
for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
  if vim.bo[bufnr].filetype == "java" then
    start_java_treesitter(bufnr)
  end
end

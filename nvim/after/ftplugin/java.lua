-- Java gets its own Treesitter activation.  This keeps the richer parser-based
-- highlighting local to Java buffers and leaves every other filetype unchanged.
local ok, err = pcall(vim.treesitter.start, 0, "java")
if not ok then
  vim.notify("Java Treesitter highlighting could not start: " .. err, vim.log.levels.WARN)
end


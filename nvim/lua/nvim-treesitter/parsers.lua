local M = {}

function M.ft_to_lang(ft)
  if not ft or ft == "" then
    return ft
  end

  return vim.treesitter.language.get_lang(ft) or ft
end

function M.get_parser(bufnr, lang)
  return vim.treesitter.get_parser(bufnr, lang)
end

return M

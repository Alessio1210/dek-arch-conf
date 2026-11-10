local M = {}

local state = {
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = false,
  },
  autotag = {
    enable = false,
  },
  incremental_selection = {},
  ensure_installed = {},
}

local function current(feature)
  local value = state[feature]
  if type(value) == "table" then
    return value
  end
  return { enable = value ~= false }
end

function M.setup(opts)
  opts = opts or {}
  state = vim.tbl_deep_extend("force", state, opts)

  local ok, treesitter = pcall(require, "nvim-treesitter")
  if ok and opts.install_dir then
    treesitter.setup({
      install_dir = opts.install_dir,
    })
  end
end

function M.is_enabled(feature, lang, _bufnr)
  local cfg = current(feature)
  if cfg.enable == false then
    return false
  end
  if cfg.enable == true or cfg.enable == nil then
    return true
  end
  if type(cfg.enable) == "table" then
    return vim.tbl_contains(cfg.enable, lang)
  end
  return false
end

function M.get_module(feature)
  if feature == "highlight" then
    local cfg = current("highlight")
    return {
      additional_vim_regex_highlighting = cfg.additional_vim_regex_highlighting or false,
    }
  end

  return current(feature)
end

function M.get_available(...)
  local ok, treesitter = pcall(require, "nvim-treesitter")
  if ok and treesitter.get_available then
    return treesitter.get_available(...)
  end

  return {}
end

function M.get_installed(...)
  local ok, treesitter = pcall(require, "nvim-treesitter")
  if ok and treesitter.get_installed then
    return treesitter.get_installed(...)
  end

  return {}
end

return M

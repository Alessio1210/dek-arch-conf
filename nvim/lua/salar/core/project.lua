local M = {}

local CONFIG_FILENAMES = { ".nvim.lua", ".nvim.project.lua" }
local ROOT_MARKERS = {
	".git",
	"pyproject.toml",
	"requirements.txt",
	"requirements-dev.txt",
	"setup.py",
	"setup.cfg",
	"tox.ini",
	"poetry.lock",
	"uv.lock",
	"Pipfile",
	"Cargo.toml",
	"CMakeLists.txt",
	"Makefile",
	"compile_commands.json",
}

local cache = {}

local function normalize(path)
	return path and vim.fs.normalize(path) or nil
end

local function is_absolute(path)
	return path:match("^%a:[/\\]") or path:match("^[/\\][/\\]") or path:sub(1, 1) == "/"
end

local function resolve_path(base_dir, value)
	if type(value) ~= "string" or value == "" then
		return nil
	end

	if value:sub(1, 1) == "~" then
		value = vim.fn.expand(value)
	end

	if is_absolute(value) then
		return normalize(value)
	end

	return normalize(vim.fs.joinpath(base_dir, value))
end

local function parse_env_file(path)
	if type(path) ~= "string" or path == "" or not vim.uv.fs_stat(path) then
		return nil
	end

	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return nil
	end

	local env = {}
	for _, line in ipairs(lines) do
		local trimmed = vim.trim(line)
		if trimmed ~= "" and not trimmed:match("^#") then
			local key, value = trimmed:match("^([^=]+)=(.*)$")
			if key and value then
				key = vim.trim(key)
				value = vim.trim(value)
				value = value:gsub("^'(.*)'$", "%1"):gsub('^"(.*)"$', "%1")
				env[key] = value
			end
		end
	end

	return env
end

local function current_start_path()
	local file = vim.api.nvim_buf_get_name(0)
	if file ~= "" then
		return file
	end

	return vim.fn.getcwd()
end

function M.find(start_path)
	local start = start_path or current_start_path()
	local config_file = vim.fs.find(CONFIG_FILENAMES, {
		path = start,
		upward = true,
		type = "file",
		limit = 1,
	})[1]

	if config_file then
		local root = vim.fn.fnamemodify(config_file, ":h")
		return normalize(root), normalize(config_file)
	end

	local root = vim.fs.root(start, ROOT_MARKERS)
	if root then
		return normalize(root), nil
	end

	return normalize(vim.fn.getcwd()), nil
end

function M.load(start_path)
	local root, config_file = M.find(start_path)
	local base_dir = root or vim.fn.getcwd()
	local cache_key = config_file or base_dir

	if cache[cache_key] ~= nil then
		return cache[cache_key], root, config_file
	end

	local config = {}
	if config_file then
		local chunk, err = loadfile(config_file)
		if chunk then
			local ok, result = pcall(chunk)
			if ok and type(result) == "table" then
				config = result
			elseif not ok then
				vim.notify(
					("Failed to load project config %s: %s"):format(config_file, result),
					vim.log.levels.WARN
				)
			end
		else
			vim.notify(
				("Failed to parse project config %s: %s"):format(config_file, err),
				vim.log.levels.WARN
			)
		end
	end

	local function materialize(value)
		if type(value) == "function" then
			value = value({
				root = root,
				config_file = config_file,
				base_dir = base_dir,
			})
		end
		return resolve_path(base_dir, value)
	end

	config.cwd = materialize(config.cwd) or base_dir
	config.python = materialize(config.python)
	config.dap = type(config.dap) == "table" and config.dap or {}
	config.dap.env = type(config.dap.env) == "table" and config.dap.env or {}
	config.dap.env_file = materialize(config.dap.env_file or config.dap.envFile)
	if not config.dap.env_file then
		local default_env_file = vim.fs.joinpath(base_dir, ".env")
		if vim.uv.fs_stat(default_env_file) then
			config.dap.env_file = default_env_file
		end
	end
	config.dap.env_from_file = parse_env_file(config.dap.env_file)
	config.root = root or base_dir
	config.config_file = config_file

	cache[cache_key] = config
	return config, root, config_file
end

function M.current(start_path)
	local config = M.load(start_path)
	return config
end

function M.cwd(start_path)
	return M.current(start_path).cwd
end

function M.python(start_path)
	return M.current(start_path).python
end

function M.resolve_python(start_path)
	local config = M.current(start_path)
	if config.python and config.python ~= "" then
		return config.python
	end

	local roots = { config.cwd, config.root, vim.fn.getcwd() }
	for _, root in ipairs(roots) do
		if root and root ~= "" then
			for _, folder in ipairs({ ".venv", "venv", "env", ".env" }) do
				local candidate = vim.fs.joinpath(root, folder, "Scripts", "python.exe")
				if vim.uv.fs_stat(candidate) then
					return normalize(candidate)
				end
			end
		end
	end

	local venv = os.getenv("VIRTUAL_ENV")
	if venv and venv ~= "" then
		local candidate = vim.fs.joinpath(venv, "Scripts", "python.exe")
		if vim.uv.fs_stat(candidate) then
			return normalize(candidate)
		end
	end

	local conda = os.getenv("CONDA_PREFIX")
	if conda and conda ~= "" then
		local candidate = vim.fs.joinpath(conda, "python.exe")
		if vim.uv.fs_stat(candidate) then
			return normalize(candidate)
		end
	end

	local py = vim.fn.exepath("py")
	if py ~= "" then
		return normalize(py)
	end

	local python3 = vim.fn.exepath("python3")
	if python3 ~= "" then
		return normalize(python3)
	end

	local python = vim.fn.exepath("python")
	if python ~= "" then
		return normalize(python)
	end

	return "python"
end

function M.debugpy_python()
	local local_python = vim.fs.joinpath(
		os.getenv("LOCALAPPDATA") or "",
		".virtualvenvs",
		"debugpy",
		"Scripts",
		"python.exe"
	)
	if vim.uv.fs_stat(local_python) then
		return normalize(local_python)
	end

	local mason_python = vim.fs.joinpath(
		os.getenv("LOCALAPPDATA") or "",
		"nvim-data",
		"mason",
		"packages",
		"debugpy",
		"venv",
		"Scripts",
		"python.exe"
	)
	if vim.uv.fs_stat(mason_python) then
		return normalize(mason_python)
	end

	local local_adapter = vim.fs.joinpath(
		os.getenv("LOCALAPPDATA") or "",
		".virtualvenvs",
		"debugpy",
		"Scripts",
		"debugpy-adapter.exe"
	)
	if vim.uv.fs_stat(local_adapter) then
		return normalize(local_python)
	end

	local mason_adapter = vim.fs.joinpath(
		os.getenv("LOCALAPPDATA") or "",
		"nvim-data",
		"mason",
		"packages",
		"debugpy",
		"venv",
		"Scripts",
		"debugpy-adapter.exe"
	)
	if vim.uv.fs_stat(mason_adapter) then
		return normalize(mason_python)
	end

	local debugpy = vim.fn.exepath("python")
	if debugpy ~= "" then
		return normalize(debugpy)
	end

	return "python"
end

function M.apply_dap_defaults(config)
	config = config or {}
	local project = M.current()

	config.cwd = project.cwd

	if (config.type == "python" or config.type == "debugpy") and not config.pythonPath and not config.python then
		config.pythonPath = project.python or M.resolve_python()
	end

	return config
end

return M

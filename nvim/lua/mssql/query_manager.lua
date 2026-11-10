local plugin_root = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "mssql.nvim", "lua", "mssql", "query_manager.lua")
local original = dofile(plugin_root)
local query_context = require("mssql.query_context")
local utils = require("mssql.utils")

local original_create_query_manager = original.create_query_manager

original.create_query_manager = function(bufnr, client)
	local query_manager = original_create_query_manager(bufnr, client)
	local owner_uri = utils.lsp_file_uri(bufnr)
	local original_execute_async = query_manager.execute_async

	query_manager.execute_async = function(query)
		query_context.set(owner_uri, query)
		return original_execute_async(query)
	end

	return query_manager
end

return original

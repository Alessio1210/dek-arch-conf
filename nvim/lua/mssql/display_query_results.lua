local utils = require("mssql.utils")
local query_context = require("mssql.query_context")

local function sanitise(tbl, limit)
	for _, record in ipairs(tbl) do
		for index, value in ipairs(record) do
			local str = tostring(value)
			if vim.fn.strdisplaywidth(str) > limit then
				str = str:sub(1, limit) .. "..."
			end
			str = str:gsub("\n", "`\\n`")
			record[index] = str
		end
	end
end

local function column_width(column_header, rows, column_index)
	local row_max = vim.iter(rows)
		:map(function(record)
			return vim.fn.strdisplaywidth(record[column_index])
		end)
		:fold(0, math.max)

	return math.max(vim.fn.strdisplaywidth(column_header), row_max)
end

local function column_widths(column_headers, rows)
	if not column_headers then
		return {}
	end

	return vim.iter(ipairs(column_headers))
		:map(function(column_index, column_header)
			return column_width(column_header, rows, column_index)
		end)
		:totable()
end

local function right_pad(str, len, char)
	if vim.fn.strdisplaywidth(str) >= len then
		return str
	end

	return str .. string.rep(char, len - vim.fn.strdisplaywidth(str))
end

local function row_to_string(row, widths)
	local padded_cells = vim.iter(ipairs(row))
		:map(function(column_index, value)
			return right_pad(value, widths[column_index], " ")
		end)
		:totable()

	return "| " .. table.concat(padded_cells, " | ") .. " |"
end

local function header_divider(widths)
	if not widths then
		return ""
	end

	local dashes_row = vim.iter(widths)
		:map(function(width)
			return string.rep("-", width)
		end)
		:totable()

	return row_to_string(dashes_row, widths)
end

local function pretty_print(column_headers, rows, max_width)
	if not column_headers then
		return ""
	end

	sanitise(rows, max_width)

	local widths = column_widths(column_headers, rows)
	local divider = header_divider(widths)
	local lines = { row_to_string(column_headers, widths), divider }

	for _, row in ipairs(rows) do
		table.insert(lines, row_to_string(row, widths))
	end

	return lines
end

local function extract_top_limit(query)
	if not query or query == "" then
		return nil
	end

	local lowered = query:lower()
	local patterns = {
		"select%s+distinct%s+top%s*%(%s*(%d+)%s*%)",
		"select%s+distinct%s+top%s+(%d+)",
		"select%s+all%s+top%s*%(%s*(%d+)%s*%)",
		"select%s+all%s+top%s+(%d+)",
		"select%s+top%s*%(%s*(%d+)%s*%)",
		"select%s+top%s+(%d+)",
	}

	for _, pattern in ipairs(patterns) do
		local top_value = lowered:match(pattern)
		if top_value then
			return tonumber(top_value)
		end
	end

	return nil
end

local result_buffers = {}

local function create_buffer(name, filetype)
	local bufnr = vim.api.nvim_create_buf(false, false)
	table.insert(result_buffers, bufnr)
	vim.api.nvim_buf_set_name(bufnr, name)
	if filetype and filetype ~= "" then
		vim.bo[bufnr].filetype = filetype
	end

	return bufnr
end

local function display_markdown(lines, bufnr)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
	vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
	vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })
	vim.api.nvim_set_option_value("readonly", true, { buf = bufnr })
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

local function show_result_set_async(column_info, subset_params, opts)
	local column_headers = vim.iter(column_info)
		:map(function(info)
			return info.columnName
		end)
		:totable()

	local rows = utils.get_rows_async(subset_params)
	local lines = pretty_print(column_headers, rows, opts.max_column_width)
	local extension = opts.results_buffer_extension or ""
	if extension ~= "" then
		extension = "." .. extension
	end

	local buf = create_buffer(
		"results " .. subset_params.batchIndex + 1 .. "-" .. subset_params.resultSetIndex + 1 .. extension,
		opts.results_buffer_filetype
	)
	vim.b[buf].query_result_info = { subset_params = subset_params }
	display_markdown(lines, buf)
	opts.open_results_in(buf)
end

local function resolve_rows_count(result, result_set_summary, opts)
	local explicit_top = extract_top_limit(query_context.get(result.ownerUri))
	local max_rows = opts.max_rows

	if explicit_top and explicit_top > 0 then
		max_rows = explicit_top
	end

	return math.min(result_set_summary.rowCount, max_rows)
end

local function display_query_results(opts, result)
	for _, result_buffer in ipairs(result_buffers) do
		if vim.api.nvim_buf_is_valid(result_buffer) then
			vim.api.nvim_buf_delete(result_buffer, { force = true })
		end
	end

	for batch_index, batch_summary in ipairs(result.batchSummaries) do
		if not batch_summary.hasError and batch_summary.resultSetSummaries then
			for result_set_index, result_set_summary in ipairs(batch_summary.resultSetSummaries) do
				local subset_params = {
					ownerUri = result.ownerUri,
					batchIndex = batch_index - 1,
					resultSetIndex = result_set_index - 1,
					rowsStartIndex = 0,
					rowsCount = resolve_rows_count(result, result_set_summary, opts),
				}

				vim.schedule(function()
					utils.try_resume(coroutine.create(function()
						show_result_set_async(result_set_summary.columnInfo, subset_params, opts)
					end))
				end)
			end
		end
	end
end

return display_query_results

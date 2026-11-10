local M = {}

local queries_by_owner_uri = {}

function M.set(owner_uri, query)
	if not owner_uri then
		return
	end

	queries_by_owner_uri[owner_uri] = query
end

function M.get(owner_uri)
	if not owner_uri then
		return nil
	end

	return queries_by_owner_uri[owner_uri]
end

return M

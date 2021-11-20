local api = vim.api
local matcher = require('fuzzy_nvim')

local defaults = {
  keyword_pattern = [[\%(-\?\d\+\%(\.\d\+\)\?\|\h\w*\%([\-]\w*\)*\)]],
	indentifier_patter = [=[[[:keyword:]]]=],
	non_indentifier_patter = [=[[^[:keyword:]]]=],
	max_buffer_lines = 20000,
	max_match_length = 50,
	max_matches = 15,
  get_bufnrs = function()
    return { vim.api.nvim_get_current_buf() }
	end,
}

local function minmax(list)
	if #list == 0 then
		error('Zero length table to minmax')
	end

	local min = list[1]
	local max = list[1]
	for _, v in ipairs(list) do
		min = math.min(min, v)
		max = math.max(max, v)
	end
	return min, max
end

local source = {}


source.extract_match = function(self, line, first_match, last_match, id_pattern, non_id_pattern)
	-- dump(line, first_match, last_match)
	local start_regex = self:regex([[.*]] .. non_id_pattern .. [[\+]] .. [[\ze]] .. id_pattern .. [[\+]])
	local end_regex = self:regex(non_id_pattern .. [[\|$]])

	local s, e = end_regex:match_str(line:sub(last_match))
	local last_match_out = last_match + (s or 2) - 1
	-- dump('end:', line:sub(last_match), (s or 'nil'), (e or 'nil'), last_match_out)

	s, e = start_regex:match_str(line:sub(1, first_match))
	local first_match_out = (e or first_match - 1) + 1
	-- dump('start:', line:sub(1, first_match), (s or 'nil'), (e or 'nil'), first_match_out)

	-- dump('out:', line:sub(first_match_out, last_match_out))
	return line:sub(first_match_out, last_match_out)
end

source.new = function()
	local self = setmetatable({}, { __index = source })
	self.regexes = {}
	return self
end

source.regex = function(self, pattern)
  self.regexes[pattern] = self.regexes[pattern] or vim.regex(pattern)
  return self.regexes[pattern]
end

source.get_keyword_pattern = function(_, params)
	if params.option.keyword_pattern then
		return params.option.keyword_pattern
	end

	-- in cmd mode we want to match everything into the search pattern
	if (vim.api.nvim_get_mode().mode == 'c') then
		return [=[[^[:blank:]].*]=]
	else
		return [[\%(-\?\d\+\%(\.\d\+\)\?\|\h\w*\%([\-]\w*\)*\)]]
	end
end


source.complete = function(self, params, callback)
	params.option = vim.tbl_deep_extend('keep', params.option, defaults)
	local is_cmd = (vim.api.nvim_get_mode().mode == 'c')
	-- in cmd mode we take all the line as a pattern
	local pattern = params.context.cursor_before_line:sub(params.offset)
	vim.schedule(function()
		local lines = {}
		for _, bufnr in ipairs(params.option.get_bufnrs()) do
			if api.nvim_buf_line_count(bufnr) <= params.option.max_buffer_lines then
				vim.list_extend(lines, api.nvim_buf_get_lines(bufnr, 0, -1, true))
			end
		end
		local items = {}
		local set = {}
		local matches = matcher:filter(pattern, lines)
		for _, result in ipairs(matches) do
			local line, positions, score = unpack(result)
			local min, max = minmax(positions)
			local item = self:extract_match(
				line,
				min,
				max,
				params.option.indentifier_patter,
				params.option.non_indentifier_patter
			)
			if item ~= pattern and set[item] == nil and #item <= params.option.max_match_length then
				set[item] = true
				table.insert(
					items,
					{
						word = (is_cmd and vim.fn.escape(item, '/?')) or item,
						label = item,
						-- cmp has a different notion of filtering completion items. We want
						-- all of out fuzzy matche to appear
						filterText = pattern,
						sortText = item,
						data = {score=score},
						dup = 0,
					})
			end
		end
		-- keep top max_matches items
		table.sort(items, function(a, b)
			return a.data.score > b.data.score
		end)
		items = {unpack(items, 1, params.option.max_matches)}

		callback({
			items = items,
			isIncomplete = true,
		})
	end
	)
end

return source

local api = vim.api

local has_fzf, matcher = pcall(require, 'cmp_fzy_buffer.fzf_matcher')
if not has_fzf then
	local has_fzy, fzy_matcher = pcall(require, 'cmp_fzy_buffer.fzy_matcher')
	if has_fzy then
		matcher = fzy_matcher
	else
		vim.notify('cmp_fzy_buffer: Cannot find niether fzy nor fzf. Please install either')
		return
	end
end


local defaults = {
  keyword_pattern = [[\%(-\?\d\+\%(\.\d\+\)\?\|\h\w*\%([\-]\w*\)*\)]],
	-- specifically dont use a regex here
	stop_characters = {
		[string.byte(' ')] = true,
		[string.byte('.')] = true,
		[string.byte('=')] = true,
		[string.byte(':')] = true,
		[string.byte('(')] = true,
		[string.byte(')')] = true,
		[string.byte('[')] = true,
		[string.byte(']')] = true,
		[string.byte('-')] = true,
		[string.byte('+')] = true,
		[string.byte('<')] = true,
		[string.byte('>')] = true,
		[string.byte(',')] = true,
		[string.byte(';')] = true,
		[string.byte('}')] = true,
		[string.byte('{')] = true,
		[string.byte('"')] = true,
		[string.byte("'")] = true,
	},
	max_buffer_lines = 20000,
	max_match_length = 50,
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

local function extract_match(line, start_match, end_match, stop_set)

	if start_match > 1 then
		while start_match > 1 and stop_set[line:byte(start_match)] == nil do
			start_match = start_match - 1
		end

		if stop_set[line:byte(start_match)] then
			start_match = start_match + 1
		end
	end

	if end_match < #line then
		while end_match < #line and stop_set[line:byte(end_match)] == nil do
			end_match = end_match + 1
		end

		if stop_set[line:byte(end_match)] then
			end_match = end_match - 1
		end
	end

	return line:sub(start_match, end_match)
end

local source = {}

source.new = function()
	local self = setmetatable({}, { __index = source })
	return self
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


source.complete = function(_, params, callback)
	params.option = vim.tbl_deep_extend('keep', params.option, defaults)
	local is_cmd = (vim.api.nvim_get_mode().mode == 'c')
	-- in cmd mode we take all the line as a pattern
	local pattern = params.context.cursor_before_line:sub(params.offset)
	vim.schedule(function()
		local lines = {}
		lines = api.nvim_buf_get_lines(params.context.bufnr, 0, -1, true)
		local items = {}
		local set = {}
		local matches = matcher:filter(pattern, lines)
		for _, result in ipairs(matches) do
			local line, positions, _ = unpack(result)
			local min, max = minmax(positions)
			local item = extract_match(line, min, max, params.option.stop_characters)
			if item ~= pattern and set[item] == nil and #item <= params.option.max_match_length then
				set[item] = true
				table.insert(
				items,
				{
					word = (is_cmd and vim.fn.escape(item, '/?')) or item,
					label = item,
				})
			end
		end
		callback({
			items = items,
			isIncomplete = true,
		})
	end
	)
end

return source

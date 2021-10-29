local api = vim.api
local fzy = require('fzy-lua-native')

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

source.complete = function(self, params, callback)
	params.option = vim.tbl_deep_extend('keep', params.option, defaults)
	local input_start = params.context:get_offset(params.option.keyword_pattern)
	local input = params.context.cursor_line:sub(input_start, params.context.cursor.col)
	local lines = {}
	for i, line in ipairs(
		api.nvim_buf_get_lines(params.context.bufnr, 0, -1, true)) do
		if i ~= params.context.cursor.row then
			table.insert(lines, line:match("^%s*(.-)%s*$"))
		end
	end
  local is_cmd = vim.api.nvim_get_mode().mode == 'c'
	vim.schedule(function()
			local items = {}
			local set = {}
			local matches = fzy.filter(input, lines, true)
			for _, result in ipairs(matches) do
				local line, positions, score = unpack(result)
				local item = extract_match(line, positions[1], positions[#positions], params.option.stop_characters)
				if set[item] == nil and #item <= params.option.max_match_length then
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

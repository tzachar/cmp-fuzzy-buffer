local api = vim.api
local matcher = require('fuzzy_nvim')

local defaults = {
	max_buffer_lines = 20000,
	max_match_length = 50,
	max_matches = 15,
  fuzzy_extra_arg = 0,
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

source.extract_matches = function(self, line, first_match, last_match, is_cmd)
  local matches = {}
  local keyword_regex = self:regex([[\k]])
  local space_regex = self:regex([[\s]])
  local starts = {}
  local ends = {}

  for i = first_match, 0, -1 do
    if keyword_regex:match_str(line:sub(i, i)) == nil then
      table.insert(starts, i + 1)
      break
    end
  end
  for i = last_match, #line + 1 do
    if i == #line + 1 or space_regex:match_str(line:sub(i, i)) then
      table.insert(ends, i - 1)
      break
    elseif keyword_regex:match_str(line:sub(i, i)) == nil then
      table.insert(ends, i - 1)
      -- keep matching
    end
  end
  if is_cmd then
    table.insert(matches, line:sub(starts[1], ends[1]))
  else
    for _, first in ipairs(starts) do
      for _, last in ipairs(ends) do
        table.insert(matches, line:sub(first, last))
      end
    end
  end

  return matches
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

source.get_keyword_pattern = function()
  if vim.api.nvim_get_mode().mode == 'c' then
    return '.*'
  else
    return [=[[^[:blank:]]\+]=]
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
        if (api.nvim_get_current_buf() == bufnr or 0 == bufnr) and not is_cmd then
          -- skip current line
          local current_line = params.context.cursor.line
          vim.list_extend(lines, api.nvim_buf_get_lines(bufnr, 0, current_line, false))
          vim.list_extend(lines, api.nvim_buf_get_lines(bufnr, current_line + 1, -1, false))
        else
          vim.list_extend(lines, api.nvim_buf_get_lines(bufnr, 0, -1, false))
        end
			end
		end
		local completions = {}
		local set = {}
		local matches = matcher:filter(pattern, lines, params.option.fuzzy_extra_arg)
		for _, result in ipairs(matches) do
			local line, positions, score = unpack(result)
			local min, max = minmax(positions)
			local items = self:extract_matches(
				line,
				min,
				max,
        is_cmd
			)
      for _, item in ipairs(items) do
        if (is_cmd or item ~= pattern) and set[item] == nil and #item <= params.option.max_match_length then
          set[item] = true
          table.insert(
            completions,
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
		end
		-- keep top max_matches items
		table.sort(completions, function(a, b)
			return a.data.score > b.data.score
		end)
		completions = {unpack(completions, 1, params.option.max_matches)}

		callback({
			items = completions,
			isIncomplete = true,
		})
	end
	)
end

return source

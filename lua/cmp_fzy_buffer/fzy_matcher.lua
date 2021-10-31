local fzy = require('fzy-lua-native')

local M = {}

-- return a list of {line, positions, score}
M.filter = function(_, pattern, lines)
	local ans = {}
	local matches = fzy.filter(pattern, lines, true)

	for _, result in ipairs(matches) do
		local line, positions, score = unpack(result)
		if #positions > 0 then
			table.insert(ans, {line, positions, score})
		end
	end

	table.sort(ans, function(a, b) return a[3] > b[3] end)
	return ans
end

return M

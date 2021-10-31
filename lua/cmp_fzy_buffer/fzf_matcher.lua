local fzf = require('fzf_lib')

local M = {}

-- return a list of {line, positions, score}
M.filter = function(_, pattern, lines)
	local ans = {}
	local slab = fzf.allocate_slab()
	local pattern_obj = fzf.parse_pattern(pattern, 0, true)

	for _, line in ipairs(lines) do
		local score = fzf.get_score(line, pattern_obj, slab)
		local positions = fzf.get_pos(line, pattern_obj, slab)
		if #positions > 0 then
			table.insert(ans, {line, positions, score})
		end
	end
	table.sort(ans, function(a, b) return a[3] > b[3] end)

	fzf.free_pattern(pattern_obj)
	fzf.free_slab(slab)
	return ans
end

return M

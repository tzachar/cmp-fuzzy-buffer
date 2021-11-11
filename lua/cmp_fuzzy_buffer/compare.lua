return function(entry1, entry2)
	if entry1.source.name == 'fuzzy_buffer' and entry2.source.name == 'fuzzy_buffer' then
			return (entry1.completion_item.data.score > entry2.completion_item.data.score)
	else
		return nil
	end
end

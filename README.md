# cmp-fuzzy-buffer

`nvim-cmp` source for fuzzy matched items from using the current buffer.
Can use either `fzf` or `fzy`.

# Installation

Depends on [fuzzy.nvim](https://github.com/tzachar/fuzzy.nvim) (which depends
either on `fzf` or on `fzy`).

Using [Packer](https://github.com/wbthomason/packer.nvim/) with `fzf`:
```lua
use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make'}
use "hrsh7th/nvim-cmp"
use {'tzachar/cmp-fuzzy-buffer', requires = {'hrsh7th/nvim-cmp', 'tzachar/fuzzy.nvim'}}
```

Using [Packer](https://github.com/wbthomason/packer.nvim/) with `fzy`:
```lua
use {'romgrk/fzy-lua-native', run = 'make'}
use "hrsh7th/nvim-cmp"
use {'tzachar/cmp-fuzzy-buffer', requires = {'hrsh7th/nvim-cmp', 'tzachar/fuzzy.nvim'}}
```

# Setup

```lua
require'cmp'.setup {
  sources = cmp.config.sources({
    { name = 'fuzzy_buffer' },
  })
}
```

This plugin can also be used to perform `/` searches with cmdline mode of cmp:
```lua
cmp.setup.cmdline('/', {
  sources = cmp.config.sources({
    { name = 'fuzzy_buffer' }
  })
})
```

In `/` search mode, the plugin will match the input string as is, without
parsing out tokens. This enables fuzzy search containing, for example, spaces.


*Note:* the plugin's name is `fuzzy_buffer` in `cmp`'s config.


# Sorting and Filtering

By default, `nvim-cmp` will filter out sequences which we matched. To prevent
this, we use the searched-for pattern as an input for `filterText`, such that
all matched strings will be returned. However, this causes `nvim-cmp` to badly
sort our returned results. To solve this issue, and sort `cmp-fuzzy-path`
results by the score returned by the fuzzy matcher, you can use the following:

```lua
local compare = require('cmp.config.compare')

cmp.setup {
	sorting = {
		priority_weight = 2,
		comparators = {
			require('cmp_fuzzy_buffer.compare'),
			compare.offset,
			compare.exact,
			compare.score,
			compare.recently_used,
			compare.kind,
			compare.sort_text,
			compare.length,
			compare.order,
		}
	},
}
```

# Configuration


## keyword_pattern (type: string)

_Default:_ `[[\%(-\?\d\+\%(\.\d\+\)\?\|\h\w*\%([\-.]\w*\)*\)]]`
_ cmdline Default:_ `[=[[^[:blank:]].*]=]`

A vim's regular expression for detecting the pattern to search with (starting
from where the cursor currently is)

## indentifier_patter (type: vim regex)
_Default:_
```lua
indentifier_patter = [=[[[:keyword:]]]=]
```

Used to find the best matched identifier to return based on the fuzzy patter and
match results.

## non_indentifier_patter (type: vim regex)
_Default:_
```lua
non_indentifier_patter = [=[[^[:keyword:]]]=],
```

Used to find the best matched identifier to return based on the fuzzy patter and
match results.

## max_buffer_lines (type: int)

Te plugin will not work in buffers with more than `max_buffer_lines` lines for
performance reasons.

_Default:_ 20000

## max_match_length (type: int)

Do not show matches longer than `max_match_length`.

_Default:_ 50

## fuzzy_extra_arg

This has different meaning depending on the fuzzy matching library used.
For `fzf`, this is the `case_mode` argument: 0 = smart_case, 1 = ignore_case, 2 = respect_case.
For `fzy`, this is the `is_case_sensitive` argument. Set to `false` to do case insensitive matching.

_Default:_ 0

## get_bufnrs (type: function)

Return a list of buffer numbers from which to get lines.

_Default_: 
```lua
get_bufnrs = function()
  return { vim.api.nvim_get_current_buf() }
end
```

If you want to use all loaded buffer, you can use the following setup:

```lua
require'cmp'.setup {
  sources = cmp.config.sources({
    { 
       name = 'fuzzy_buffer' ,
       option = {
          get_bufnrs = function()  
          local bufs = {}
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
            if buftype ~= 'nofile' and buftype ~= 'prompt' then
              bufs[#bufs + 1] = buf
            end
          end
          return bufs
          end
       },
    },
  })
}
```

## max_matches (type: int)

Maximal number of matches to returl.

_Default:_ 15

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

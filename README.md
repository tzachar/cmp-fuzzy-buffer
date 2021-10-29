# cmp-fzy-buffer

nvim-cmp source for fuzzy matched items from using the current buffer.

# Installation

Depends on [fzy-lua-native](https://github.com/romgrk/fzy-lua-native).

Using [Packer](https://github.com/wbthomason/packer.nvim/):
```lua
use {'romgrk/fzy-lua-native', run = 'make'}
use "hrsh7th/nvim-cmp"
use {'tzachar/cmp-fzy-buffer', requires = {'hrsh7th/nvim-cmp', 'romgrk/fzy-lua-native'}}
```

# Setup

```lua
require'cmp'.setup {
  sources = cmp.config.sources({
    { name = 'fzy_buffer' },
  })
}
```

This plugin can also be used to perform `/` searches with cmdline mode of cmp:
```lua
cmp.setup.cmdline('/', {
  sources = cmp.config.sources({
    { name = 'fzy_buffer' }
  })
})
```

*Note:* the plugin's name is `fzy_buffer` in `cmp`'s config.

# Configuration


## keyword_pattern (type: string)

_Default:_ `[[\%(-\?\d\+\%(\.\d\+\)\?\|\h\w*\%([\-.]\w*\)*\)]]`

A vim's regular expression for detecting the pattern to search with (starting
from where the cursor currently is)

You can set this to `\k\+` if you want to use the `iskeyword` option for recognizing words.

## stop_characters (type: table)

_Default:_
```lua
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
}
```

When fzy found a fuzzy match, we need to translate the fuzzy match to a
suggestion. The `stop_characters` table allows us to define the suggestion item
by expanding the boudries of fzy's match until we encounter a character in
`stop_characters`.


## max_buffer_lines (type: int)

Te plugin will not work in buffers with more than `max_buffer_lines` lines for
performance reasons.

_Default:_ 20000

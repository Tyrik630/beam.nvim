# beam.nvim

**🖖 Beam me up! Transport your text operations across file moving only when required.**

`beam.nvim` makes it possible to perform text operations (yank, delete, change, visual selection) anywhere in your file using search, while moving only when needed.

<div align="center">

[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1+-blue.svg?style=flat-square&logo=lua)](https://www.lua.org)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

</div>

## How it works

Press `,yi"` or other text object → Search for any string → Press Enter → The quotes at that location are yanked, and you're still where you started.

No jumping. No marks. No macros. Just pure efficiency.

## Quick Examples

```vim
,yi"<Enter>     " Yank inside the NEXT quotes (empty search)
,dip            " Search & delete inside paragraph
,ci(func        " Search for 'func' & change inside parentheses
,vimclass       " Search for 'class' & select inside code block
,Y              " Search & yank entire line
```

## Features

### Core Features
- **Native Search Integration**: Uses Vim's `/` search with incremental highlighting
- **Visual Feedback**: See what you're about to operate on before it happens
- **Smart Position Restore**: Stay where you are (or intelligently move for edits)
- **All Text Objects**: Works with every text object you have installed
- **Ctrl-G/T Navigation**: Navigate through matches while searching before committing
- **Line Operators**: Special `Y`, `D`, `C`, `V` operators for entire lines
- **WhichKey Support**: Automatic integration if you have WhichKey installed
- **Custom Text Objects**: Register your own text objects via simple API
- **Zero Dependencies**: Pure Lua implementation, no external requirements

## QoL Features

- Empty search instantly operates on the next text object with the same search pattern.
- Search highlight to see exactly what will be affected before the operation completes.
- Status line integration helps you to know what operation is pending with the optional statusline indicator.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "Piotr1215/beam.nvim",
  config = function()
    require("beam").setup()  -- Uses default prefix ','
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "Piotr1215/beam.nvim",
  config = function()
    require("beam").setup()  -- Uses default prefix ','
  end,
}
```

**Note:** The plugin uses `,` as the default prefix. All mappings like `,yi"`, `,dap`, etc. are automatically created. You can customize the prefix in the setup (see Configuration section).

## Configuration

### Default Setup

```lua
require('beam').setup({
  prefix = ',',                      -- Your prefix key (mini-leader)
  visual_feedback_duration = 150,    -- ms to show selection
  clear_highlight = true,            -- Clear search highlight after operation
  clear_highlight_delay = 500,       -- ms before clearing
})
```

### Custom Text Objects

beam.nvim can define its own text objects that work with all beam operations. This is useful when you want text objects that don't exist globally but should work with remote operations.

```lua
require('beam').setup({
  prefix = ',',
  enable_default_text_objects = true, -- Enables beam's built-in text objects (currently: im/am for markdown code blocks)
  custom_text_objects = {
    -- Simple format: Just a description for beam operations
    -- NOTE: This assumes the text object already exists (e.g., from treesitter-textobjects)
    -- It only adds beam keymaps like ,yiF but doesn't create the iF/aF text object itself
    ['F'] = 'function (treesitter)',
    
    -- Full format: Creates the actual text object AND adds beam operations
    -- This creates the ir/ar text objects that work everywhere in Vim
    ['r'] = {
      desc = 'Ruby block',
      select = function(inclusive)
        -- Your text object implementation
        -- inclusive: true for 'around', false for 'inside'
        if inclusive then
          vim.cmd('normal! vaB')  -- around block
        else
          vim.cmd('normal! viB')  -- inside block
        end
      end
    }
  }
})

-- Or register them dynamically
require('beam').register_text_object('z', 'custom zone')

-- Register with implementation
require('beam').register_text_object('g', {
  desc = 'git conflict',
  select = function(inclusive)
    -- Implementation to select git conflict markers
  end
})
```

**Built-in Text Objects:**
- `im`/`am` - Inside/around markdown code block (triple backticks) - enabled with `enable_default_text_objects = true`

### Statusline Integration

Add the pending operation indicator to your statusline:

![Statusline Indicator](static/status-line.png)

```lua
-- Lualine
sections = {
  lualine_x = {
    function() return vim.g.beam_search_operator_indicator or '' end
  }
}

-- Native statusline
vim.opt.statusline:append('%{get(g:,"beam_search_operator_indicator","")}')
```

## Usage

### Basic Operations

All operations follow the pattern: `{prefix}{operator}{text-object-modifier}{text-object}`

| Keys | Description |
|------|-------------|
| `,yi"` | Search & yank inside quotes |
| `,dap` | Search & delete around paragraph |
| `,ciw` | Search & change inside word |
| `,vi{` | Search & select inside curly braces |

### Quick Mode (Empty Search = Next)

Just press Enter without typing to operate on the NEXT occurrence:

| Keys | Action |
|------|--------|
| `,yi"<Enter>` | Yank inside NEXT quotes |
| `,dip<Enter>` | Delete NEXT paragraph |
| `,cif<Enter>` | Change NEXT function |

### Line Operations

Special uppercase operators for entire lines:

| Keys | Description |
|------|-------------|
| `,Y` | Search & yank entire line |
| `,D` | Search & delete entire line |
| `,C` | Search & change entire line |
| `,V` | Search & visual select entire line |

### Search Navigation

While searching, use these keys to navigate matches:
- `Ctrl-G` - Jump to next match
- `Ctrl-T` - Jump to previous match
- `Enter` - Execute operation at current match
- `Esc` - Cancel operation

## Integration with Other Plugins

### Treesitter Text Objects

```lua
local beam = require('beam')
if beam then
  beam.register_text_objects({
    ['f'] = 'function (treesitter)',
    ['c'] = 'class (treesitter)',
    ['l'] = 'loop (treesitter)',
    ['a'] = 'parameter (treesitter)',
  })
end
```

### mini.ai

```lua
-- After setting up mini.ai
local beam = require('beam')
if beam then
  beam.register_text_objects({
    ['f'] = 'function (mini.ai)',
    ['a'] = 'argument (mini.ai)',
  })
end
```

## Commands

| Command | Description |
|---------|-------------|
| `:BeamReload` | Reload the plugin configuration |

## Troubleshooting

### Quick health check
Run `:checkhealth beam` to diagnose common issues.

### Mappings not working?
- Check if your prefix key is already mapped: `:verbose nmap <prefix>` (where `<prefix>` is your configured prefix, default is `,`)
- Ensure the plugin is loaded: `:lua print(vim.g.loaded_beam)`
- Verify your configuration: `:lua print(vim.inspect(require('beam').get_config()))`

### Operations not executing?
- Make sure you have the text objects installed that you're trying to use
- Check `:messages` for any error output

### Inspiration

Inspired by the power of Vim's composable operations and the desire to operate on text without losing context as well as several excellent Neovim plugins that explore innovative ways of navigating and manipulating text:

- [flash.nvim](https://github.com/folke/flash.nvim) - Jump to any location with minimal keystrokes
- [leap.nvim](https://github.com/ggandor/leap.nvim) - General-purpose motion plugin with 2-character search
- [hop.nvim](https://github.com/phaazon/hop.nvim) - Neovim motions on speed
- [vim-sneak](https://github.com/justinmk/vim-sneak) - The missing motion for Vim

While these plugins focus on cursor movement, beam.nvim takes a different approach: **operate on remote text, moving only when it makes sense** - stay in place for yank and delete, jump to location for change and visual selection.

## License

MIT 

---

<div align="center">

[Report Bug](https://github.com/Piotr1215/beam.nvim/issues) · [Request Feature](https://github.com/Piotr1215/beam.nvim/issues)

</div>

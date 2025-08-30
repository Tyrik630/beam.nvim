# beam.nvim

**🖖 Beam me up! Transport your text operations across file moving only when required.**

[![Video Thumbnail](https://img.youtube.com/vi/NYC38m4Z47o/0.jpg)](https://www.youtube.com/watch?v=NYC38m4Z47o)

`beam.nvim` makes it possible to perform text operations (yank, delete, change, visual selection) anywhere in your file using search, while moving only when needed.

<div align="center">

[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1+-blue.svg?style=flat-square&logo=lua)](https://www.lua.org)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

</div>


## Quick Examples

```vim
,yi"func        " Search for 'func' & yank inside quotes at that location
,dip            " Search & delete inside paragraph
,ci(func        " Search for 'func' & change inside parentheses
,vimclass       " Search for 'class' & select inside code block
,Y              " Search & yank entire line
```


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

## Features

- **Native Search Integration** - Uses Vim's `/` search with incremental highlighting
- **Universal Text Object Support** - Works with ALL text objects from any plugin
- **Motion Support** - Handles single-letter motions (`L` for URL, `Q` for quote, etc.)
- **Cross-Buffer Operations** - Search and operate across all open buffers
- **Auto-Discovery** - Automatically finds and uses all text objects from your plugins
- **Visual Feedback** - Shows selection briefly before operation executes
- **Smart Position Restore** - Yank/delete returns to origin, change/visual stays at target
- **Search Navigation** - Use `Ctrl-G`/`Ctrl-T` to navigate matches while searching
- **Line Operators** - Special `Y`, `D`, `C`, `V` operators for entire lines
- **Statusline Integration** - See pending operations in your statusline
- **Custom Text Objects** - Define your own text objects
- **Zero Dependencies** - Pure Lua implementation, no external requirements

## Usage

### How it Works

1. Press `,yi"` (or any operator + text object)
2. Search for your target location
3. Press Enter
4. Operation executes there, cursor returns (for yank/delete)

### Basic Operations

| Keys | Description |
|------|-------------|
| `,yi"` | Search & yank inside quotes |
| `,dap` | Search & delete around paragraph |
| `,ciw` | Search & change inside word |
| `,vi{` | Search & select inside curly braces |

### Search Navigation

While searching:
- `Ctrl-G` - Next match
- `Ctrl-T` - Previous match  
- `Enter` - Execute
- `Esc` - Cancel

### Commands

| Command | Description |
|---------|-------------|
| `:BeamReload` | Reload the plugin configuration |
| `:BeamDiscoverNow` | Manually trigger text object discovery |
| `:BeamShowTextObjects` | Display all discovered text objects |

## Configuration

### Default Setup

```lua
require('beam').setup({
  prefix = ',',                      -- Your prefix key (mini-leader)
  visual_feedback_duration = 150,    -- ms to show selection
  clear_highlight = true,            -- Clear search highlight after operation
  clear_highlight_delay = 500,       -- ms before clearing
  cross_buffer = false,              -- Enable cross-buffer operations
  auto_discover_text_objects = true, -- Auto-discover all available text objects
  show_discovery_notification = true,-- Show notification about discovered objects
  excluded_text_objects = {},       -- Exclude specific text objects (e.g., {'q', 'z'})
  excluded_motions = {},             -- Exclude specific motions (e.g., {'Q', 'R'})
})
```

### Cross-Buffer Operations

When `cross_buffer = true`, beam searches across all open buffers:

- **Yank/Delete** - Performs operation and returns you to original position
- **Change/Visual** - Opens target buffer in split or switches to it

```vim
" Example: Yank quotes from another buffer
,yi"<Enter>searchterm<Enter>
" Finds 'searchterm' in any buffer, yanks quotes, returns home
```

### Auto-Discovery

With `auto_discover_text_objects = true`, beam automatically discovers and registers:

- **nvim-various-textobjs** - `iq` (any quote), `ih` (headers), `L` (URL motion)
- **mini.ai** - All your custom text objects  
- **treesitter-textobjects** - `if` (function), `ic` (class), etc.
- **Built-in Vim** - All standard text objects

This gives you instant access to 100+ combinations like:
- `,yih` - Search & yank markdown header
- `,ciq` - Search & change any quote type
- `,dL` - Search & delete to URL

### Excluding Text Objects and Motions

You can exclude specific text objects or motions from auto-discovery:

```lua
require('beam').setup({
  auto_discover_text_objects = true,
  excluded_text_objects = { 'q', 'z' },  -- Exclude iq/aq and iz/az
  excluded_motions = { 'Q', 'R' },       -- Exclude Q and R motions
})
```

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

### Full Configuration with All Options

```lua
require('beam').setup({
  -- Core settings
  prefix = ',',                      -- Prefix for all mappings
  
  -- Visual feedback
  visual_feedback_duration = 150,    -- Duration to show selection before operation
  clear_highlight = true,            -- Clear search highlight after operation
  clear_highlight_delay = 500,       -- Delay before clearing highlight
  
  -- Advanced features
  cross_buffer = false,              -- Search and operate across all buffers
  auto_discover_text_objects = true, -- Discover text objects from all plugins
  show_discovery_notification = true,-- Notify about discovered objects
  excluded_text_objects = {},       -- List of text object keys to exclude (e.g., {'q', 'z'})
  excluded_motions = {},             -- List of motion keys to exclude (e.g., {'Q', 'R'})
  
  -- Custom text objects (in addition to discovered ones)
  enable_default_text_objects = true, -- Enable beam's built-in text objects
  custom_text_objects = {
    -- Your custom text objects here
  }
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

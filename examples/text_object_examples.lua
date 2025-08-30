-- Example configurations for different text object scenarios

-- SCENARIO 1: You have nvim-treesitter-textobjects installed
-- It provides text objects like if/af (function), ic/ac (class), etc.
require('beam').setup({
  prefix = ',',
  custom_text_objects = {
    -- These assume treesitter text objects already exist
    -- Just adds beam operations (,yif, ,dif, etc.)
    ['f'] = 'function',
    ['c'] = 'class', 
    ['l'] = 'loop',
    ['a'] = 'parameter',
  }
})

-- SCENARIO 2: You want to create NEW text objects
require('beam').setup({
  prefix = ',',
  enable_default_text_objects = true, -- Creates im/am for markdown
  custom_text_objects = {
    -- This creates a brand new text object 'ix'/'ax' for XML tags
    ['x'] = {
      desc = 'XML/HTML tag',
      select = function(inclusive)
        if inclusive then
          vim.cmd('normal! vat')  -- around tag
        else
          vim.cmd('normal! vit')  -- inside tag
        end
      end
    },
    
    -- This creates 'ih'/'ah' for markdown headers
    ['h'] = {
      desc = 'markdown header',
      select = function(inclusive)
        -- Find the current header line
        vim.cmd('?^#')  -- search backward for #
        if inclusive then
          vim.cmd('normal! V')  -- select whole line
        else
          vim.cmd('normal! ^w')  -- skip the # symbols
          vim.cmd('normal! v$')  -- select to end of line
        end
      end
    }
  }
})

-- SCENARIO 3: Mixed - some exist, some are new
require('beam').setup({
  prefix = ',',
  enable_default_text_objects = true,
  custom_text_objects = {
    -- These already exist from other plugins
    ['f'] = 'function (from treesitter)',
    ['c'] = 'comment (from Comment.nvim)',
    
    -- This is NEW
    ['d'] = {
      desc = 'double brackets [[...]]',
      select = function(inclusive)
        vim.cmd('call search("\\[\\[", "cb")')
        if inclusive then
          vim.cmd('normal! v')
          vim.cmd('call search("\\]\\]", "e")')
        else
          vim.cmd('normal! 2lv')
          vim.cmd('call search("\\]\\]")')
          vim.cmd('normal! 2h')
        end
      end
    }
  }
})

-- HOW TO CHECK WHAT TEXT OBJECTS EXIST:
-- 1. Try using them directly: di{object} in normal mode
-- 2. Check your plugin configs:
--    - nvim-treesitter-textobjects: provides @function.inner, @class.outer, etc.
--    - targets.vim: provides additional text objects
--    - vim-textobj-*: various text object plugins
-- 3. List operator-pending mappings: :omap

-- COMMON EXISTING TEXT OBJECTS FROM POPULAR PLUGINS:

-- From nvim-treesitter-textobjects (when configured):
-- if/af - function
-- ic/ac - class/struct  
-- il/al - loop
-- is/as - scope
-- ia/aa - parameter
-- i?/a? - conditional

-- From targets.vim:
-- in(/an( - next parentheses
-- il(/al( - last parentheses
-- in'/an' - next quotes
-- etc.

-- From mini.ai:
-- i?/a? - configurable smart text objects

-- Built-in Vim text objects (always available):
-- iw/aw - word
-- iW/aW - WORD
-- is/as - sentence
-- ip/ap - paragraph
-- i"/a" - quotes
-- i(/a( - parentheses
-- i[/a[ - brackets
-- i{/a{ - braces
-- it/at - tags (HTML/XML)
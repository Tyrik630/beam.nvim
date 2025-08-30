local M = {}
local config = require('beam.config')

-- Try to load common text object plugins to ensure they're available
local function ensure_plugins_loaded()
  -- Trigger VeryLazy event to load lazy-loaded plugins
  vim.api.nvim_exec_autocmds('User', { pattern = 'VeryLazy' })

  -- Also try to directly load known text object plugins
  local plugins_to_load = {
    'various-textobjs',
    'mini.ai',
    'nvim-treesitter.configs',
    'nvim-treesitter-textobjects',
    'targets.vim',
  }

  for _, plugin in ipairs(plugins_to_load) do
    pcall(require, plugin)
  end

  -- Give plugins a moment to register their mappings
  vim.wait(50)
end

-- List of common text objects to check for
-- Format: { keymap = "text object key", desc = "description" }
local COMMON_TEXT_OBJECTS = {
  -- Built-in Vim text objects
  { keymap = 'iw', desc = 'inner word' },
  { keymap = 'aw', desc = 'around word' },
  { keymap = 'iW', desc = 'inner WORD' },
  { keymap = 'aW', desc = 'around WORD' },
  { keymap = 'is', desc = 'inner sentence' },
  { keymap = 'as', desc = 'around sentence' },
  { keymap = 'ip', desc = 'inner paragraph' },
  { keymap = 'ap', desc = 'around paragraph' },
  { keymap = 'i"', desc = 'inner double quotes' },
  { keymap = 'a"', desc = 'around double quotes' },
  { keymap = "i'", desc = 'inner single quotes' },
  { keymap = "a'", desc = 'around single quotes' },
  { keymap = 'i`', desc = 'inner backticks' },
  { keymap = 'a`', desc = 'around backticks' },
  { keymap = 'i(', desc = 'inner parentheses' },
  { keymap = 'a(', desc = 'around parentheses' },
  { keymap = 'ib', desc = 'inner parentheses' },
  { keymap = 'ab', desc = 'around parentheses' },
  { keymap = 'i[', desc = 'inner brackets' },
  { keymap = 'a[', desc = 'around brackets' },
  { keymap = 'i{', desc = 'inner braces' },
  { keymap = 'a{', desc = 'around braces' },
  { keymap = 'iB', desc = 'inner braces' },
  { keymap = 'aB', desc = 'around braces' },
  { keymap = 'i<', desc = 'inner angle brackets' },
  { keymap = 'a<', desc = 'around angle brackets' },
  { keymap = 'it', desc = 'inner tag' },
  { keymap = 'at', desc = 'around tag' },

  -- nvim-various-textobjs (only actual text objects, not motions)
  { keymap = 'iq', desc = 'inner any quote' },
  { keymap = 'aq', desc = 'around any quote' },
  { keymap = 'ii', desc = 'inner indentation' },
  { keymap = 'ai', desc = 'around indentation' },
  { keymap = 'iI', desc = 'inner indentation (with line above)' },
  { keymap = 'aI', desc = 'around indentation (with lines above/below)' },
  -- Removed: R, r, Q, |, L - these are motions, not text objects
  { keymap = 'ig', desc = 'inner entire buffer' },
  { keymap = 'ag', desc = 'around entire buffer' },
  { keymap = 'in', desc = 'inner near end of line' },
  { keymap = 'an', desc = 'around near end of line' },
  { keymap = 'iS', desc = 'inner subword' },
  { keymap = 'aS', desc = 'around subword' },
  { keymap = 'iv', desc = 'inner value' },
  { keymap = 'av', desc = 'around value' },
  { keymap = 'ik', desc = 'inner key' },
  { keymap = 'ak', desc = 'around key' },
  { keymap = 'in', desc = 'inner number' },
  { keymap = 'an', desc = 'around number' },
  { keymap = 'id', desc = 'inner diagnostic' },
  { keymap = 'ad', desc = 'around diagnostic' },
  { keymap = 'iz', desc = 'inner fold' },
  { keymap = 'az', desc = 'around fold' },
  { keymap = 'ie', desc = 'inner entire visible' },
  { keymap = 'ae', desc = 'around entire visible' },
  { keymap = 'iC', desc = 'inner css selector' },
  { keymap = 'aC', desc = 'around css selector' },
  { keymap = 'ix', desc = 'inner html attribute' },
  { keymap = 'ax', desc = 'around html attribute' },
  { keymap = 'iD', desc = 'inner double square brackets' },
  { keymap = 'aD', desc = 'around double square brackets' },
  { keymap = 'iP', desc = 'inner python triple quotes' },
  { keymap = 'aP', desc = 'around python triple quotes' },
  { keymap = 'iJ', desc = 'inner javascript regex' },
  { keymap = 'aJ', desc = 'around javascript regex' },
  { keymap = 'iA', desc = 'inner shell pipe' },
  { keymap = 'aA', desc = 'around shell pipe' },

  -- Treesitter text objects
  { keymap = 'if', desc = 'inner function' },
  { keymap = 'af', desc = 'around function' },
  { keymap = 'ic', desc = 'inner class' },
  { keymap = 'ac', desc = 'around class' },
  { keymap = 'ia', desc = 'inner parameter' },
  { keymap = 'aa', desc = 'around parameter' },
  { keymap = 'il', desc = 'inner loop' },
  { keymap = 'al', desc = 'around loop' },
  { keymap = 'io', desc = 'inner conditional' },
  { keymap = 'ao', desc = 'around conditional' },
  { keymap = 'ih', desc = 'inner markdown header' },
  { keymap = 'ah', desc = 'around markdown header' },

  -- mini.ai additions
  { keymap = 'i_', desc = 'inner underscore' },
  { keymap = 'a_', desc = 'around underscore' },
  { keymap = 'i-', desc = 'inner dash' },
  { keymap = 'a-', desc = 'around dash' },
  { keymap = 'i/', desc = 'inner slash' },
  { keymap = 'a/', desc = 'around slash' },
  { keymap = 'i=', desc = 'inner equals' },
  { keymap = 'a=', desc = 'around equals' },

  -- targets.vim style
  { keymap = 'in(', desc = 'inner next parentheses' },
  { keymap = 'il(', desc = 'inner last parentheses' },
  { keymap = 'in{', desc = 'inner next braces' },
  { keymap = 'il{', desc = 'inner last braces' },
  { keymap = 'in[', desc = 'inner next brackets' },
  { keymap = 'il[', desc = 'inner last brackets' },
}

-- Check if a text object is available
function M.is_text_object_available(text_obj)
  -- Method 1: Check operator-pending mode mappings
  for _, map in ipairs(vim.api.nvim_get_keymap('o')) do
    if map.lhs == text_obj then
      return true, 'mapped'
    end
  end

  -- Method 2: Check visual mode mappings
  for _, map in ipairs(vim.api.nvim_get_keymap('x')) do
    if map.lhs == text_obj then
      return true, 'mapped'
    end
  end

  -- Method 3: Test if it actually works (for built-ins)
  -- Only test known built-in text objects to avoid side effects
  local known_builtins = {
    'iw',
    'aw',
    'iW',
    'aW',
    'is',
    'as',
    'ip',
    'ap',
    'i"',
    'a"',
    "i'",
    "a'",
    'i`',
    'a`',
    'i(',
    'a(',
    'i)',
    'a)',
    'ib',
    'ab',
    'i[',
    'a[',
    'i]',
    'a]',
    'i{',
    'a{',
    'i}',
    'a}',
    'iB',
    'aB',
    'i<',
    'a<',
    'i>',
    'a>',
    'it',
    'at',
  }

  for _, builtin in ipairs(known_builtins) do
    if text_obj == builtin then
      return true, 'builtin'
    end
  end

  return false, nil
end

-- Discover all available text objects
function M.discover_text_objects()
  -- Ensure plugins are loaded first
  ensure_plugins_loaded()

  local available = {}
  local seen = {}
  local config = require('beam.config')

  -- Build exclusion set for faster lookups
  local excluded = {}
  for _, key in ipairs(config.current.excluded_text_objects or {}) do
    -- Handle both the suffix (e.g., 'q') and full forms (e.g., 'iq', 'aq')
    excluded[key] = true
    excluded['i' .. key] = true
    excluded['a' .. key] = true
  end

  -- First, check our curated list of common text objects
  for _, text_obj in ipairs(COMMON_TEXT_OBJECTS) do
    -- Skip if excluded
    if not excluded[text_obj.keymap] and not excluded[text_obj.keymap:sub(2)] then
      local is_available, source = M.is_text_object_available(text_obj.keymap)
      if is_available and not seen[text_obj.keymap] then
        text_obj.source = source
        table.insert(available, text_obj)
        seen[text_obj.keymap] = true
      end
    end
  end

  -- Additionally, discover from actual mappings (only real text objects with i/a prefix)
  for _, map in ipairs(vim.api.nvim_get_keymap('o')) do
    local lhs = map.lhs
    -- Text objects must be at least 2 chars (i/a + something) and start with i or a
    if lhs and #lhs >= 2 and #lhs <= 3 and not seen[lhs] then
      local first = lhs:sub(1, 1)
      if first == 'i' or first == 'a' then
        -- Only add if it looks like a reasonable text object
        local suffix = lhs:sub(2)
        -- Skip if suffix contains special characters that don't make sense
        if not suffix:match('[^%w%p]') and #suffix <= 2 then
          table.insert(available, {
            keymap = lhs,
            desc = map.desc or (first == 'i' and 'inner ' or 'around ') .. suffix,
            source = 'mapped',
          })
          seen[lhs] = true
        end
      end
    end
    -- Skip single-letter mappings - they're motions, not text objects!
  end

  return available
end

-- Get a formatted list of available text objects
function M.get_available_text_objects()
  local available = M.discover_text_objects()
  local categorized = {
    quotes = {},
    brackets = {},
    words = {},
    functions = {},
    custom = {},
    other = {},
  }

  for _, obj in ipairs(available) do
    local key = obj.keymap
    if key:match('["\']') or key:match('q') then
      table.insert(categorized.quotes, obj)
    elseif key:match('[%(%[%{<]') or key:match('b') or key:match('B') then
      table.insert(categorized.brackets, obj)
    elseif key:match('w') or key:match('W') or key:match('s') or key:match('p') then
      table.insert(categorized.words, obj)
    elseif key:match('f') or key:match('c') or key:match('a') then
      table.insert(categorized.functions, obj)
    elseif #key > 2 then
      table.insert(categorized.custom, obj)
    else
      table.insert(categorized.other, obj)
    end
  end

  return categorized, available
end

-- Discover motions (single-letter operator-pending mappings)
function M.discover_motions()
  ensure_plugins_loaded()

  local motions = {}
  local config = require('beam.config')

  -- Build exclusion set
  local excluded = {}
  for _, key in ipairs(config.current.excluded_motions or {}) do
    excluded[key] = true
  end

  -- Check for single-letter operator-pending mappings
  for _, map in ipairs(vim.api.nvim_get_keymap('o')) do
    local lhs = map.lhs
    -- Single letter mappings that aren't built-in vim motions and not excluded
    if lhs and #lhs == 1 and not lhs:match('[hjklwbeWBE0$^{}()]') and not excluded[lhs] then
      -- These are likely custom motions from plugins
      local desc = map.desc or 'motion to ' .. lhs
      motions[lhs] = desc
    end
  end

  -- Add known motions from nvim-various-textobjs
  local known_motions = {
    ['L'] = 'url',
    ['Q'] = 'to next quote',
    ['R'] = 'rest of paragraph',
    ['r'] = 'rest of indentation',
    ['|'] = 'column',
  }

  for motion, desc in pairs(known_motions) do
    -- Skip if excluded
    if not excluded[motion] then
      -- Check if it actually exists
      local exists = false
      for _, map in ipairs(vim.api.nvim_get_keymap('o')) do
        if map.lhs == motion then
          exists = true
          motions[motion] = desc
          break
        end
      end
    end
  end

  return motions
end

-- Auto-register discovered text objects with beam
function M.auto_register_text_objects(options)
  options = options or {}
  local conflict_resolution = options.conflict_resolution or 'skip'

  local available = M.discover_text_objects()
  local beam = require('beam')
  local registered = 0
  local skipped = 0
  local conflicts = {}

  -- Track which suffixes we've seen (to handle i/a pairs)
  local seen_suffixes = {}

  for _, text_obj in ipairs(available) do
    local full_key = text_obj.keymap
    local prefix = full_key:sub(1, 1) -- i or a
    local suffix = full_key:sub(2) -- the actual text object key

    -- Check if this suffix was already processed
    if not seen_suffixes[suffix] then
      seen_suffixes[suffix] = true

      -- Check if this text object is already configured in beam
      if beam.is_text_object_registered(suffix) then
        -- Already registered in beam's config, skip
        skipped = skipped + 1
      else
        -- Not in beam's config, safe to add
        if beam.register_text_object(suffix, text_obj.desc) then
          registered = registered + 1
        else
          skipped = skipped + 1
        end
      end
    end
  end

  -- Also discover and register motions
  local motions = M.discover_motions()
  local motions_registered = 0

  for motion, desc in pairs(motions) do
    if not config.motions[motion] then
      config.motions[motion] = desc
      motions_registered = motions_registered + 1
    end
  end

  -- Re-setup mappings to include newly discovered motions
  if motions_registered > 0 then
    require('beam.mappings').setup()
  end

  return {
    registered = registered,
    skipped = skipped,
    total = #available,
    conflicts = conflicts,
    motions_registered = motions_registered,
    motions_total = vim.tbl_count(motions),
  }
end

return M

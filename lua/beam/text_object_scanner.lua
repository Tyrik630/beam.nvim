local M = {}

-- Scan for all possible text object mappings
function M.scan_all_text_objects()
  local discovered = {}
  local checked = {}

  -- Common text object prefixes
  local prefixes = { 'i', 'a' }

  -- Get all operator-pending and visual mode mappings
  local function get_mappings(mode)
    local maps = {}
    -- Get all mappings for the mode
    local all_maps = vim.api.nvim_get_keymap(mode)

    for _, map in ipairs(all_maps) do
      local lhs = map.lhs
      -- Check if it looks like a text object (starts with i or a)
      if lhs and #lhs >= 2 then
        local first_char = lhs:sub(1, 1)
        if first_char == 'i' or first_char == 'a' then
          maps[lhs] = {
            lhs = lhs,
            rhs = map.rhs or '',
            desc = map.desc or '',
            source = map.sid and 'plugin' or 'user',
            mode = mode,
          }
        end
      end
    end
    return maps
  end

  -- Scan operator-pending mode
  local op_maps = get_mappings('o')
  for lhs, info in pairs(op_maps) do
    if not checked[lhs] then
      discovered[lhs] = info
      checked[lhs] = true
    end
  end

  -- Scan visual mode (some text objects might only be in visual)
  local vis_maps = get_mappings('x')
  for lhs, info in pairs(vis_maps) do
    if not checked[lhs] then
      discovered[lhs] = info
      checked[lhs] = true
    end
  end

  -- Check for built-in text objects by testing them
  local function test_builtin_text_object(obj)
    -- Try to use the text object in a safe way
    local ok = pcall(function()
      vim.cmd('normal! v' .. obj .. '\027') -- v{obj}<Esc>
    end)
    return ok
  end

  -- Common built-in text object suffixes to test
  local builtin_suffixes = {
    'w',
    'W',
    's',
    'p', -- words, sentences, paragraphs
    '"',
    "'",
    '`', -- quotes
    '(',
    ')',
    '[',
    ']',
    '{',
    '}',
    '<',
    '>', -- brackets
    'b',
    'B', -- parentheses/braces aliases
    't', -- tags
  }

  -- Test combinations
  for _, prefix in ipairs(prefixes) do
    for _, suffix in ipairs(builtin_suffixes) do
      local obj = prefix .. suffix
      if not checked[obj] then
        -- Save cursor position
        local save_cursor = vim.api.nvim_win_get_cursor(0)

        -- Test if this text object works
        if test_builtin_text_object(obj) then
          discovered[obj] = {
            lhs = obj,
            desc = 'builtin ' .. (prefix == 'i' and 'inner' or 'around') .. ' ' .. suffix,
            source = 'builtin',
            mode = 'ox',
          }
          checked[obj] = true
        end

        -- Restore cursor
        pcall(vim.api.nvim_win_set_cursor, 0, save_cursor)
      end
    end
  end

  return discovered
end

-- Get a categorized view of discovered text objects
function M.categorize_text_objects(discovered)
  local categorized = {
    quotes = {},
    brackets = {},
    words = {},
    code = {},
    custom = {},
    other = {},
  }

  for lhs, info in pairs(discovered) do
    local suffix = lhs:sub(2) -- Remove i/a prefix
    local category = 'other'

    if suffix:match('["\']') or suffix:match('^q$') or suffix:match('^Q$') then
      category = 'quotes'
    elseif suffix:match('[%(%[%{<>%]%}%)]') or suffix:match('^[bB]$') then
      category = 'brackets'
    elseif suffix:match('^[wWsp]$') then
      category = 'words'
    elseif
      suffix:match('^[fclamhdoACFLM]$')
      or info.desc:match('function')
      or info.desc:match('class')
    then
      category = 'code'
    elseif #suffix > 1 or info.source == 'plugin' then
      category = 'custom'
    end

    table.insert(categorized[category], {
      lhs = lhs,
      suffix = suffix,
      info = info,
    })
  end

  -- Sort each category
  for _, objects in pairs(categorized) do
    table.sort(objects, function(a, b)
      return a.lhs < b.lhs
    end)
  end

  return categorized
end

-- Get a formatted report of discovered text objects
function M.get_discovery_report(with_details)
  local discovered = M.scan_all_text_objects()
  local categorized = M.categorize_text_objects(discovered)

  local report = {}
  local total = 0

  for category, objects in pairs(categorized) do
    if #objects > 0 then
      table.insert(report, string.format('  %s (%d):', category, #objects))

      if with_details then
        for _, obj in ipairs(objects) do
          local desc = obj.info.desc ~= '' and obj.info.desc or (obj.info.source .. ' text object')
          table.insert(report, string.format('    %s - %s', obj.lhs, desc))
        end
      else
        -- Just list the text objects
        local list = {}
        for _, obj in ipairs(objects) do
          table.insert(list, obj.lhs)
        end
        table.insert(report, '    ' .. table.concat(list, ', '))
      end

      total = total + #objects
    end
  end

  table.insert(report, 1, string.format('Discovered %d text objects:', total))

  return table.concat(report, '\n'), discovered
end

-- Intelligently register discovered text objects with beam
function M.auto_register_with_beam()
  local discovered = M.scan_all_text_objects()
  local beam = require('beam')
  local registered = 0
  local skipped = 0
  local conflicts = {}

  for lhs, info in pairs(discovered) do
    -- Extract the suffix (removing i/a prefix)
    local suffix = lhs:sub(2)

    -- Check if beam already has this registered
    if not beam.is_text_object_registered(suffix) then
      -- Generate a description
      local desc = info.desc
      if desc == '' then
        local prefix = lhs:sub(1, 1)
        desc = (prefix == 'i' and 'inner ' or 'around ') .. suffix
      end

      -- Register with beam
      if beam.register_text_object(suffix, desc) then
        registered = registered + 1
      else
        skipped = skipped + 1
      end
    else
      skipped = skipped + 1
      table.insert(conflicts, lhs)
    end
  end

  return {
    registered = registered,
    skipped = skipped,
    total = vim.tbl_count(discovered),
    conflicts = conflicts,
  }
end

return M

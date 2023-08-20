local finders = require('telescope.finders')
local cvs_diff = require('cvs.diff')

local function change(e)
  if e.rev1 and e.rev2 then
    return 'M'
  elseif e.rev1 then
    return 'D'
  elseif e.rev2 then
    return 'A'
  else
    return '?'
  end
end

local function make_entry(diff_entry)
  local file = diff_entry.file
  return {
    value = diff_entry,
    filename = file,
    ordinal = file,
    display = function ()
      local label = string.format('%s %s', change(diff_entry), file)
      local hl = { { { 0, 1 }, 'Keyword' } }
      return label, hl
    end,
  }
end

local function make_table_finder(results)
  return finders.new_table{
    results = results,
    entry_maker = make_entry,
  }
end

return function (finder_options)
  if finder_options.results then
    return make_table_finder(finder_options.results)
  else
    local files = finder_options.files or {}
    local opts = finder_options.opts or {}
    local results = cvs_diff(files, opts)
    local finder = make_table_finder(results)
    finder._from_log = finder_options.from_log
    return finder
  end
end

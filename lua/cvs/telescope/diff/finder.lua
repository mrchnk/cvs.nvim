local finders = require('telescope.finders')
local cvs = require('cvs.sys')
local cvs_hl = require('cvs.ui.highlight')

local function change(e)
  if e.rev1 and e.rev2 then
    return 'M'
  elseif e.rev1 then
    return 'R'
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
      local hl = { { { 0, 1 }, cvs_hl.id.status } }
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

local function file_as_diff(file)
  local cmd = string.format('diff -U0 /dev/null "%s"', file)
  return vim.fn.systemlist(cmd)
end

local function append_unversioned(results, dir)
  local cmd = string.format('cvs -nq up %s 2>/dev/null', dir or '')
  local lines = vim.fn.systemlist(cmd)
  for _, line in ipairs(lines) do
    if vim.startswith(line, '? ') then
      local file = string.sub(line, 3)
      table.insert(results, {
        file = file,
        body = file_as_diff(file)
      })
    end
  end
end

return function (finder_options)
  if finder_options.results then
    return make_table_finder(finder_options.results)
  else
    local files = finder_options.files or {}
    local opts = finder_options.opts or {}
    local results = cvs.diff(files, opts)
    if not opts.rev_date then
      -- diff last rev with current
      if #files == 0 then
        append_unversioned(results)
      else
        for _, name in ipairs(files) do
          if vim.fn.isdirectory(name) then
            append_unversioned(results, name)
          end
        end
      end
    end
    local finder = make_table_finder(results)
    finder._from_log = finder_options.from_log
    finder._files = files
    finder._opts = opts
    return finder
  end
end

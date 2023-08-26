local finders = require('telescope.finders')
local cvs = require('cvs.sys')
local cvs_hl = require('cvs.ui.highlight')

local function make_entry(log_entry)
  local title = log_entry.title
  local author = log_entry.author
  return {
    value = log_entry,
    ordinal = title,
    display = function ()
      local text = string.format('%s: %s', author, title)
      local hl = { { { 0, #author+1 }, cvs_hl.id.author } }
      return text, hl
    end,
  }
end

local function ts(date)
  local Y, M, D, h, m, s = string.match(date, '(%d+)-(%d%d)-(%d%d) (%d%d):(%d%d):(%d%d)')
  return os.time{
    year = Y,
    month = M,
    day = D,
    hour = h,
    min = m,
    sec = s,
  }
end

local function make_commits_log(log)
  local map = {}
  local results = {}
  for _, log_entry in ipairs(log) do
    for _, commit in ipairs(log_entry.commits) do
      local id = commit.commitid
      local entry
      if map[id] then
        entry = map[id]
      else
        entry = {
          title = commit.title,
          message = commit.message,
          date = commit.date,
          author = commit.author,
          ts = ts(commit.date),
          files = {}
        }
        map[id] = entry
        table.insert(results, entry)
      end
      table.insert(entry.files, {
        file = log_entry.file,
        rev = commit.rev,
      })
    end
  end
  return results
end

local function make_table_finder(results)
  return finders.new_table{
    results = make_commits_log(results),
    entry_maker = make_entry,
  }
end

local function have_commit(commits, rev)
  for _, commit in ipairs(commits) do
    if commit.rev == rev then
      return true
    end
  end
  return false
end

local function make_cmd_finder(files, opts)
  local started
  local finished
  local closed
  local idx = 0
  local results = {}
  local callbacks = {}
  local day = 0
  local _opts = setmetatable({}, {__index = opts})
  local files_done = {}
  local function run()
    if closed then
      return
    end
    day = day + 1
    if day == 1 then
      _opts.date_range = '>=1 day ago'
    else
      _opts.date_range = string.format('%s day ago<=%s day ago', day, day-1)
    end
    local log = cvs.log(files, _opts)
    for _, v in ipairs(make_commits_log(log)) do
      local entry = make_entry(v)
      idx = idx + 1
      results[idx] = entry
      for _, cb in ipairs(callbacks) do
        cb[1](entry)
      end
    end
    local finish = true
    for _, file in ipairs(log) do
      if files_done[file.file] then
        -- skip
      elseif have_commit(file.commits, '1.1') then
        files_done[file.file] = true
      else
        finish = false
      end
    end
    if finish then
      finished = true
      for _, cb in ipairs(callbacks) do
        cb[2]()
      end
    else
      vim.schedule(run)
    end
  end
  return setmetatable({
    close = function ()
      closed = true
    end,
    results = results,
  }, {
    __call = function (_, _, process_result, process_complete)
      if not started then
        started = true
        vim.schedule(run)
      else
        for _, entry in ipairs(results) do
          process_result(entry)
        end
      end
      if finished then
        process_complete()
      else
        table.insert(callbacks, {process_result, process_complete})
      end
    end,
  })
end

return function (finder_opts)
  if finder_opts.results then
    return make_table_finder(finder_opts.results)
  else
    local files = finder_opts.files or {}
    local opts = finder_opts.opts or {}
    local results = cvs.log(files, opts)
    local finder = make_table_finder(results)
    finder._files = files
    return finder
  end
end


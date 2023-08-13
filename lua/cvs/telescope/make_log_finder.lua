local finders = require('telescope.finders')
local cvs_log = require('cvs.log')

local function make_entry(log_entry)
  local title = log_entry.title
  local author = log_entry.author
  return {
    value = log_entry,
    ordinal = title,
    display = function ()
      local text = string.format('%s: %s', author, title)
      local hl = { { { 0, #author+1 }, 'Constant' } }
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
  local result = {}
  local function add(commit, log_entry)
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
      table.insert(result, entry)
    end
    table.insert(entry.files, {
      file = log_entry.file,
      rev = commit.rev,
    })
  end
  for _, log_entry in ipairs(log) do
    for _, commit in ipairs(log_entry.commits) do
      add(commit, log_entry)
    end
  end
  return result
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
    local log = cvs_log(files, _opts)
    vim.print(files, _opts, log)
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
        vim.print(file.file)
        finish = false
      end
    end
    if finish or day == 14 then
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
    entry_maker = make_entry,
  }, {
    __call = function (_, _, process_result, process_complete)
      if not started then
        started = true
        vim.schedule(run)
      else
        for _, v in ipairs(results) do
          process_result(v)
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
    if opts.date_range then
      local results = cvs_log(files, opts)
      return make_table_finder(results)
    else
      return make_cmd_finder(files, opts)
    end
  end
end


local finders = require('telescope.finders')

local function make_entry(log_entry)
  return {
    value = log_entry,
    ordinal = log_entry.title,
    display = log_entry.title,
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

return function (log)
  local results = make_commits_log(log)
  return finders.new_table{
    results = results,
    entry_maker = make_entry,
  }
end


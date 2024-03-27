local run = require('cvs.sys.run')
local FILE_SEP = '============================================================================='
local COMMIT_SEP = '----------------------------'

local function cvs_log(files, opts)
  local date_range = opts.date_range and {'-d', opts.date_range} or {}
  local author = opts.author and '-w' .. table.concat(opts.author, ',') or {}
  return run({
    'log',
    date_range,
    author,
    files,
  }, { expect_code = 0 })
end

local function ts(date)
  local Y, M, D, h, m, s = string.match(date, '(%d+)[-/](%d%d)[-/](%d%d) (%d%d):(%d%d):(%d%d)')
  return os.time{
    year = Y,
    month = M,
    day = D,
    hour = h,
    min = m,
    sec = s,
  }
end

local function make_entry(head, commits)
  local file
  for _, line in ipairs(head) do
    if vim.startswith(line, 'Working file: ') then
      file = string.sub(line, 15)
    end
  end
  return {
    file = file,
    head = head,
    commits = commits,
  }
end


local function commit_message(lines)
  local message
  for i = 3, #lines do
    local line = lines[i]
    if message then
      table.insert(message, line)
    elseif #line > 0 then
      message = {line}
    end
  end
  return message
end

local function make_commit(lines)
  local message = commit_message(lines)
  local title = message[1]
  local rev
  if vim.startswith(lines[1], 'revision ') then
    rev = string.sub(lines[1], 10)
  end
  local commit = {
    rev = rev,
    title = title,
    message = message,
  }
  for kv in vim.gsplit(lines[2], ';%s*', {trimempty=true}) do
    local k, v = string.match(kv, '(%a+):%s+(.*)')
    commit[k] = v
  end
  if commit.date then
    local success, t = pcall(ts, commit.date)
    if success then
      commit.ts = t
    end
  end
  return commit
end

local function parse(lines)
  local result = {}
  local head = {}
  local commits = {}
  local commit
  local function add_entry()
    table.insert(result, make_entry(head, commits))
  end
  local function add_commit()
    if commit then
      table.insert(commits, make_commit(commit))
    end
  end
  for _, line in ipairs(lines) do
    if line == FILE_SEP then
      add_commit()
      add_entry()
      commit = nil
      commits = {}
      head = {}
    elseif line == COMMIT_SEP then
      add_commit()
      commit = {}
    elseif commit then
      table.insert(commit, line)
    else
      table.insert(head, line)
    end
  end
  return result
end

return function (files, opts)
  local lines = cvs_log(files, opts)
  local result = parse(lines)
  return result
end


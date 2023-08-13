local FILE_SEP = '============================================================================='
local COMMIT_SEP = '----------------------------'

local function make_args(tbl, prefix)
  if not tbl or #tbl == 0 then
    return ''
  end
  return table.concat(vim.tbl_map(function (value)
    if prefix then
      return string.format('%s "%s"', prefix, value)
    else
      return string.format('"%s"', value)
    end
  end, tbl), ' ')
end

local function cvs_log(files, opts)
  local date_range = opts.date_range
  local author = opts.author and table.concat(opts.author, ',')
  local cmd = string.format('TZ=UTC cvs log %s 2>/dev/null', table.concat({
    date_range and string.format('-d "%s"', date_range) or '',
    author and string.format('-w%s', author) or '',
    make_args(files),
  }, ' '))
  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error > 0 then
    error(lines[1])
  end
  return lines
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

local function make_commit(lines)
  local message = {unpack(lines, 3)}
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
    if not commit then
      return
    end
    table.insert(commits, make_commit(commit))
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


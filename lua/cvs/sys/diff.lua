local run = require('cvs.sys.run')
local FILE_SEP = '==================================================================='

local function cvs_diff(files, opts)
  return run {
    '-n', 'diff', '-N',
    '-u', '-U', opts.context or 3,
    opts.rev_date,
    files,
  }
end

local function get_rev(line)
  local name, date, rev = unpack(vim.split(line, '\t'))
  if string.sub(name, 5) == '/dev/null' then
    return nil
  else
    return rev or 'HEAD'
  end
end

local function make_entry(file, head, body)
  if #body == 1 then
    return {
      file = file,
      rev2 = 'HEAD',
      head = head,
      body = body,
    }
  end
  return {
    file = file,
    rev1 = get_rev(body[2]),
    rev2 = get_rev(body[3]),
    head = head,
    body = body,
  }
end

local function parse(lines)
  local result = {}
  local file
  local head
  local body
  local function add_entry()
    if body then
      table.insert(result, make_entry(file, head, body))
      head = nil
      body = nil
      file = nil
    end
  end
  for _, line in ipairs(lines) do
    if vim.startswith(line, 'Index: ') then
      add_entry()
      file = string.sub(line, 8)
    elseif body then
      table.insert(body, line)
    elseif vim.startswith(line, 'diff ') then
      body = {line}
    elseif head then
      table.insert(head, line)
    elseif line == FILE_SEP then
      head = {}
    end
  end
  add_entry()
  return result
end

return function (files, opts)
  files = files or {}
  opts = opts or {}
  local lines = cvs_diff(files, opts)
  local result = parse(lines)
  return result
end

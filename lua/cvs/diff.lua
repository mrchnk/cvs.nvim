local FILE_SEP = '==================================================================='

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

local function cvs_diff(files, opts)
  local cmd = string.format('TZ=UTC cvs -n diff %s 2>/dev/null', table.concat({
    '-N',
    make_args({opts.context or 3}, '-U'),
    opts.rev_date and table.concat(opts.rev_date, ' ') or '',
    make_args(files)
  }, ' '))
  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error == 0 then
    error('No changes found')
  end
  return lines
end

local function make_entry(file, head, body)
  local rev1
  local rev2
  for _, line in ipairs(head) do
    if vim.startswith(line, "retrieving revision ") then
      local rev = string.sub(line, 21)
      if rev2 then
        error('Three revisions diff?')
      elseif rev1 then
        rev2 = rev
      else
        rev1 = rev
      end
    end
  end
  return {
    file = file,
    rev1 = rev1,
    rev2 = rev2,
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
  local lines = cvs_diff(files, opts)
  local result = parse(lines)
  return result
end

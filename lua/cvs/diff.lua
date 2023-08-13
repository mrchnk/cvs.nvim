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

local function cvs_diff(files, flags)
  local cmd = string.format('cvs -n diff -N -U %s', table.concat({
    flags.context or 3,
    flags.rev_date and table.concat(flags.rev_date, ' ') or '',
    make_args(files)
  }, ' '))
  local result = vim.fn.system(cmd)
  if vim.v.shell_error == 0 then
    error('No changes found')
  end
  return result
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
    head = head,
    body = body,
    rev1 = rev1,
    rev2 = rev2,
  }
end

local function parse(diff)
  local lines = vim.split(diff, '\n')
  -- trim last line
  lines[#lines] = nil
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
    if vim.startswith(line, 'cvs diff: ') then
      -- extra output
    elseif vim.startswith(line, 'Index: ') then
      add_entry()
      file = string.sub(line, 8)
    elseif body then
      table.insert(body, line)
    elseif vim.startswith(line, 'diff ') then
      body = {line}
    elseif head then
      table.insert(head, line)
    elseif line == '===================================================================' then
      head = {}
    end
  end
  add_entry()
  return result
end

return function (files, flags)
  local out = cvs_diff(files, flags)
  local result = parse(out)
  return result
end

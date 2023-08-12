local function cvs_diff(opts)
  local result = vim.fn.system('cvs -n diff -U 3 -N')
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

return function (opts)
  local out = cvs_diff(opts)
  local result = parse(out)
  vim.print(result)
  return result
end

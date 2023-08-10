local function cvs_diff(opts)
  local result = vim.fn.system('cvs diff -U 3 -N')
  if vim.v.shell_error == 0 then
    error('No changes found')
  end
  return result
end

local function parse(diff)
  local lines = vim.split(diff, "\n")
  local entry
  local result = {}
  local read_diff = false
  for _, line in ipairs(lines) do
    if vim.startswith(line, "cvs diff: Diffing ") then
      -- mac cvs header
    elseif vim.startswith(line, "Index: ") then
      local file = string.sub(line, 8)
      entry = {
        file = file,
        head = {},
        diff = {},
      }
      table.insert(result, entry)
      read_diff = false
    elseif vim.startswith(line, "diff ") then
      read_diff = true;
    end
    if entry then
      if read_diff then
        table.insert(entry.diff, line)
      else
        table.insert(entry.head, line)
      end
    end
  end
  return result
end

return function (opts)
  local out = cvs_diff(opts)
  local result = parse(out)
  return result
end

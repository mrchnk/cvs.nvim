local function cvs_up(file)
  local result = vim.fn.system('cvs up -p ' .. file)
  if vim.v.shell_error > 0 then
    error(result)
  end
  return result
end

local function make_entry(head, body)
  local entry = {
    head = head,
    body = body,
  }
  for _, line in ipairs(head) do
    if vim.startswith(line, "Checking out ") then
      entry.file = string.sub(line, 14)
    elseif vim.startswith(line, "VERS: ") then
      entry.rev = string.sub(line, 7)
    end
  end
  return entry;
end

local function parse(out)
  local lines = vim.split(out, "\n")
  -- remove nl at the end
  lines[#lines] = nil
  local result = {}
  local head
  local body
  local function add_entry()
    if head and body then
      table.insert(result, make_entry(head, body))
    end
    head = nil
    body = nil
  end
  for _, line in ipairs(lines) do
    if line == "===================================================================" then
      add_entry()
      head = {}
    elseif line == "***************" then
      body = {}
    elseif body then
      table.insert(body, line)
    elseif head then
      table.insert(head, line)
    end
  end
  add_entry()
  return result
end

return function (file)
  local out = cvs_up(file)
  local result = parse(out)
  return result
end

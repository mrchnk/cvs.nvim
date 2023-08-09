local _M = {}
local values_iterator = require('cvs.util.values_iterator')

local function _parse_range(range)
  local first, last = string.match(range, '(%d+),(%d+)')
  if first and last and range == first .. ',' .. last then
    return {tonumber(first), tonumber(last)}
  else
    return tonumber(range)
  end
end

local function _to_range(range)
  if type(range) == 'number' then
    return {range, range}
  elseif type(range) == 'table' then
    return range
  end
  error('wrong diff format')
end

local function _expect_number(num)
  if type(num) == 'number' then
    return num
  end
  error('wrong diff format')
end

local function _parse(lines)
  local it = values_iterator(lines)
  local function read_line()
    local line = it()
    return string.sub(line, 3)
  end
  local function read_lines(range)
    if type(range) == 'number' then
      return {read_line()}
    elseif type(range) ~= 'table' then
      error('wrong diff format')
    end
    local first, last = unpack(range)
    local res = {}
    for _ = first, last do
      table.insert(res, read_line())
    end
    return res
  end
  local function read_delim()
    local line = it()
    assert(line == '---', 'wrong diff format')
  end
  local head = {}
  local commands = {}
  for line in it do
    if vim.startswith(line, 'retrieving revision ') then
      local rev = string.sub(line, 21)
      if head.rev1 then
        head.rev2 = rev
      else
        head.rev1 = rev
      end
    elseif vim.startswith(line, 'diff ') then
      break
    end
  end
  for line in it do
    local r1, cmd, r2 = string.match(line, '([%d,]+)([acd])([%d,]+)')
    if r1 and cmd and r2 and line == r1 .. cmd .. r2 then
      r1 = _parse_range(r1)
      r2 = _parse_range(r2)
      if cmd == 'a' then
        table.insert(commands, {cmd,
          {_expect_number(r1), _to_range(r2)},
          {{}, read_lines(r2)}})
      elseif cmd == 'c' then
        table.insert(commands, {cmd,
          {_to_range(r1), _to_range(r2)},
          {
            read_lines(r1),
            read_delim() or read_lines(r2),
          }})
      elseif cmd == 'd' then
        table.insert(commands, {cmd,
          {_to_range(r1), _expect_number(r2)},
          {read_lines(r1), {}}})
      end
    end
  end
  return commands, head
end

local function _patch(lines, commands_it)
  local result = {}
  local i = 0
  local it = values_iterator(lines)
  local function add(before)
    while i < before do
      local line = it()
      table.insert(result, line)
      i = i + 1
    end
  end
  local function skip(before)
    while i < before do
      it()
      i = i + 1
    end
  end
  for range, patch in commands_it do
    if type(range) == 'number' then
      add(range)
    else
      local rb, re = unpack(range)
      add(rb-1)
      skip(re)
    end
    for _, line in ipairs(patch) do
        table.insert(result, line)
    end
  end
  for line in it do
    table.insert(result, line)
  end
  return result;
end

_M.parse = _parse

function _M.patch(file, commands)
  return _patch(file, values_iterator(commands, function(cmd)
    if not cmd then
      return
    end
    local _, range, patch = unpack(cmd)
    return range[1], patch[2]
  end))
end

function _M.unpatch(file, commands)
  return _patch(file, values_iterator(commands, function(cmd)
    if not cmd then
      return
    end
    local _, range, patch = unpack(cmd)
    return range[2], patch[1]
  end))
end

return _M


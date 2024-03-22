local run = require('cvs.sys.run')

local function cvs_up(files)
  return run({
    '-nq', 'up',
    files,
  }, {expect_code = 0})
end

local function parse(lines)
  local result = {}
  for _, line in ipairs(lines) do
    local status = string.sub(line, 1, 1)
    local file = string.sub(line, 3)
    table.insert(result, {status, file})
  end
  return result
end

return function (files)
  files = files or {}
  local lines = cvs_up(files)
  local result = parse(lines)
  return result
end

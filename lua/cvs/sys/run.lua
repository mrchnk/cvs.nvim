local log = require('cvs.log')

local function escape(arg)
  if string.find(arg, '[ <>]') then
    return '"' .. arg .. '"'
  end
  return arg
end

return function (args, opts)
  args = vim.tbl_map(escape, vim.tbl_flatten(args))
  opts = opts or {}
  local cmd = 'cvs ' .. table.concat(args, ' ')
  local full_cmd = 'TZ=UTC ' .. cmd .. ' 2>/dev/null'
  log(cmd)
  local lines = vim.fn.systemlist(full_cmd)
  local code = vim.v.shell_error
  if opts.expect_code and code ~= opts.expect_code then
    error(string.format('CVS sys failed (%s) code=%d', cmd, code))
  end
  return lines, code
end


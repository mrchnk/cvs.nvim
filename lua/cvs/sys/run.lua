local function escape(arg)
  if string.find(arg, '[ <>]') then
    return '"' .. arg .. '"'
  end
  return arg
end

return function (args, opts)
  args = vim.tbl_map(escape, vim.tbl_flatten(args))
  opts = opts or {}
  local cmd = opts.cmd or 'cvs'
  cmd = cmd .. ' ' .. table.concat(args, ' ')
  local final_cmd = 'TZ=UTC ' .. cmd
  if not opts.error_output then
    final_cmd = final_cmd .. ' 2>/dev/null'
  end
  local lines = vim.fn.systemlist(final_cmd)
  local code = vim.v.shell_error
  if opts.expect_code and code ~= opts.expect_code then
    error(string.format('CVS sys failed (%s) code=%d', cmd, code))
  end
  return lines, code
end

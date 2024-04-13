local Job = require('plenary.job')

local function escape(arg)
  if string.find(arg, '[ <>]') then
    return '"' .. arg .. '"'
  end
  return arg
end

local function exec(args, opts)
  args = vim.tbl_map(escape, args)
  opts = opts or {}
  local cmd = opts.cmd or 'cvs'
  cmd = cmd .. ' ' .. table.concat(args, ' ')
  return vim.cmd('!' .. cmd)
end

local function find_command(name)
  local command = vim.fn.systemlist('which ' .. name)
  if vim.v.shell_error ~= 0 then
    error(string.format('Command %s not found', name))
  end
  return command[1]
end

return function (args, opts)
  args = args and vim.tbl_flatten(args) or {}
  opts = opts or {}
  if opts.exec then
    return exec(args, opts)
  end
  local cmd = opts.cmd or 'cvs'
  local stdout = {}
  local stderr = {}
  local job = Job:new{
    command = find_command(cmd),
    args = args,
    env = { TZ = 'UTC' },
    on_stdout = function (_, line)
      table.insert(stdout, line)
    end,
    on_stderr = function (_, line)
      if opts.error_output then
        table.insert(stdout, line)
      else
        table.insert(stderr, line)
      end
    end,
  }
  local _, code = job:sync()
  if opts.expect_code and code ~= opts.expect_code then
    error(string.format('Command %s failed with code %d', cmd, code))
  end
  return stdout, code
end


local make_args = require('cvs.make_args')

local function cvs_up(files, args)
  local cmd = string.format('!cvs up %s', table.concat({
    table.concat(args, ' '),
    make_args(files)
  }, ' '))
  vim.cmd(cmd)
end

return function (files, opts)
  cvs_up(files, {'-C'})
end


local make_args = require('cvs.make_args')

local function cvs_up(files, args)
  local cmd = string.format('cvs up %s', table.concat({
    table.concat(args, ' '),
    make_args(files)
  }, ' '))
  local out = vim.fn.system(cmd)
  vim.fn.input('!' .. cmd .. '\n' .. out .. '\nPress any key...')
end

return function (files, opts)
  cvs_up(files, {'-C'})
end


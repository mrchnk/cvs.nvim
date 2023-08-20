local make_args = require('cvs.utils.make_args')

local function cvs_up(files)
  local cmd = string.format('cvs up -C %s', table.concat({
    make_args(files)
  }, ' '))
  local out = vim.fn.system(cmd)
  if vim.v.shell_error > 0 then
    error(out)
  end
  vim.fn.input('!' .. cmd .. '\n' .. out .. '\nPress any key...')
end

return function (files, opts)
  cvs_up(files)
end


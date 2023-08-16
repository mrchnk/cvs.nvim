local make_args = require('cvs.make_args')

return function (files)
  local cmd = string.format('!cvs -e $VIM commit %s', make_args(files))
  vim.cmd(cmd)
end

local cvs_log = require('cvs.log')
local parse_args = require('cvs.cmd.parse_args')

return function (opts)
  local files, opts = parse_args(opts.args)
  local log = cvs_log(files, opts)
  vim.print(log)
end

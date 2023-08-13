local cvs_log = require('cvs.log')
local telescope_log = require('cvs.telescope.log')
local parse_args = require('cvs.cmd.parse_args')

return function (opts)
  local files, opts = parse_args(opts.args)
  telescope_log({files = files, opts = opts})
end

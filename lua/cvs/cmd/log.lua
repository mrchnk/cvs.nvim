local telescope_log = require('cvs.telescope.log.picker')
local parse_args = require('cvs.cmd.parse_args')

return function (command_options)
  local files, opts = parse_args(command_options.args)
  telescope_log{
    files = files,
    opts = opts,
  }
end

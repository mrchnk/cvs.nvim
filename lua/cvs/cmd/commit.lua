local parse_args = require('cvs.cmd.parse_args')
local ui_commit = require('cvs.ui.commit')

return function (command_options)
  local files, opts = parse_args(command_options.args)
  ui_commit(files)
end

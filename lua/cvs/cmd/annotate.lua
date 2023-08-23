local annotate_ui = require('cvs.ui.annotate')
local parse_args = require('cvs.cmd.parse_args')

return function (annotate_options)
  local files, opts = parse_args(annotate_options.args)
  annotate_ui{
    file = #files == 1 and files[1] or nil,
    rev = opts.rev,
  }
end

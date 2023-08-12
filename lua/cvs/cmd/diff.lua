local cvs_diff = require('cvs.diff')
local ui_diff = require('cvs.ui.diff')
local telescope_diff = require('cvs.telescope.diff')
local parse_args = require('cvs.cmd.parse_args')

return function (opts)
  local files, flags = parse_args(opts.args)
  local diff_results = cvs_diff(files, flags)
  if #files == 1 then
    ui_diff(diff_results[1])
  else
    telescope_diff(diff_results)
  end
end

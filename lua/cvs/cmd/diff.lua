local cvs_diff = require('cvs.diff')
local ui_diff = require('cvs.ui.diff')
local telescope_diff = require('cvs.telescope.diff')

local function parse_args(args)
  if #args > 0 then
    return {args[1]}, {}
  end
  return {}, {}
end

return function (opts)
  local files, flags = parse_args(opts.fargs)
  local diff_results = cvs_diff(files, flags)
  if #files == 1 then
    ui_diff(diff_results[1])
  else
    telescope_diff(diff_results)
  end
end

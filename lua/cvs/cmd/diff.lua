local cvs_diff = require('cvs.diff')
local telescope_diff = require('cvs.telescope.diff')

return function (opts)
  local diff_results = cvs_diff()
  telescope_diff(diff_results)
end

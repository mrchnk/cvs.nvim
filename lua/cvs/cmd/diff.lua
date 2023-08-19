local cvs_diff = require('cvs.diff')
local ui_diff = require('cvs.ui.diff')
local telescope_diff = require('cvs.telescope.diff.picker')
local parse_args = require('cvs.cmd.parse_args')

local function is_file(name)
  return vim.fn.filereadable(name) == 1
end

return function (command_options)
  local files, opts = parse_args(command_options.args)
  if #files == 1 and is_file(files[1]) then
    local diff_results = cvs_diff(files, opts)
    ui_diff(diff_results[1])
  else
    telescope_diff{
      files = files,
      opts = opts,
    }
  end
end

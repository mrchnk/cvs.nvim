local make_buf_previewer = require('cvs.telescope.make_buf_previewer')
local format_commit = require('cvs.utils.format_commit')

local function format_entry(entry, prompt)
  return format_commit(entry.value, prompt)
end

return function ()
  return make_buf_previewer{
    format_entry = format_entry,
  }
end


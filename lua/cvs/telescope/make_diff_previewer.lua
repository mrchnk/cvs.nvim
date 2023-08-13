local make_buf_previewer = require('cvs.telescope.make_buf_previewer')

local function format_entry(entry, prompt)
  return entry.value.body
end

return function ()
  return make_buf_previewer{
    setup_buf = function (buf)
      vim.api.nvim_buf_set_option(buf, 'syntax', 'diff')
    end,
    format_entry = format_entry,
  }
end

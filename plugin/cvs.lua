local telescope_diff = require('cvs.telescope_diff')

vim.api.nvim_create_user_command("CVSDiff", function (opts)
  telescope_diff()
end, {
  desc = 'Print changed files',
  complete = 'file',
  nargs = '?',
})


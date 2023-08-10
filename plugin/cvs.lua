local telescope_diff = require('cvs.telescope.diff')

vim.api.nvim_create_user_command("CVSDiff", function (opts)
  telescope_diff(opts)
end, {
  desc = 'Print changed files',
  complete = 'file',
  nargs = '?',
})


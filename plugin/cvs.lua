local cmd = require('cvs.cmd')

vim.api.nvim_create_user_command("CVSDiff", cmd.diff, {
  desc = 'Print changed files',
  complete = 'file',
  nargs = '?',
})


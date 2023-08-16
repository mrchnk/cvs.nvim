local cmd = require('cvs.cmd')

vim.api.nvim_create_user_command("CVSDiff", cmd.diff, {
  desc = 'Print changed files',
  complete = 'file',
  nargs = '?',
})

vim.api.nvim_create_user_command("CVSLog", cmd.log, {
  desc = 'Print changed files',
  complete = 'file',
  nargs = '?',
})

vim.api.nvim_create_user_command('CVSCommit', cmd.commit, {
  desc = 'Commit changed files',
  complete = 'file',
  nargs = '?',
})


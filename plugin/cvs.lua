local cmd = require('cvs.cmd')
local cvs_hl = require('cvs.ui.highlight')

cvs_hl.setup()

vim.api.nvim_create_user_command("CVSDiff", cmd.diff, {
  desc = 'Show diff for selected file(s) and revision(s) or cwd status',
  complete = 'file',
  nargs = '?',
})

vim.api.nvim_create_user_command("CVSLog", cmd.log, {
  desc = 'Show log for selected file(s) or cwd',
  complete = 'file',
  nargs = '?',
})

vim.api.nvim_create_user_command('CVSCommit', cmd.commit, {
  desc = 'Commit selected file(s) or staged changes',
  complete = 'file',
  nargs = '?',
})

vim.api.nvim_create_user_command('CVSAnnotate', cmd.annotate, {
  desc = 'Annotate current buffer',
  complete = 'file',
  nargs = '?'
})


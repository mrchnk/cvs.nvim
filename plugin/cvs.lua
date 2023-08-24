local cmd = require('cvs.cmd')
local cvs_hl = require('cvs.ui.highlight')

cvs_hl.setup()

vim.api.nvim_create_user_command(cmd.id.diff, cmd.diff, {
  desc = 'Show diff for selected file(s) and revision(s) or cwd status',
  complete = 'file',
  nargs = '?',
})

vim.api.nvim_create_user_command(cmd.id.log, cmd.log, {
  desc = 'Show log for selected file(s) or cwd',
  complete = 'file',
  nargs = '?',
})

vim.api.nvim_create_user_command(cmd.id.commit, cmd.commit, {
  desc = 'Commit selected file(s) or staged changes',
  complete = 'file',
  nargs = '?',
})

vim.api.nvim_create_user_command(cmd.id.annotate, cmd.annotate, {
  desc = 'Annotate current buffer',
  complete = 'file',
  nargs = '?'
})


vim.api.nvim_create_user_command("CVSDiff", function (opts)
  local diff = vim.fn.system('cvs -qn update')
  print(diff)
end, {
  desc = 'Print changed files',
  nargs = 0,
})


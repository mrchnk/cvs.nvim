return function (file)
  vim.cmd.badd(file)
  return vim.fn.bufnr(file)
end


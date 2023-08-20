local function cvs_remove(file)
  local tmp = vim.fn.tempname()
  local cmd = string.format('cvs remove "%s"', file)
  vim.fn.rename(file, tmp)
  local out = vim.fn.system(cmd)
  local is_error = vim.v.shell_error > 0
  vim.fn.rename(tmp, file)
  if is_error then
    error(out)
  end
end

return function (files)
  for _, file in ipairs(files) do
    cvs_remove(file)
  end
end


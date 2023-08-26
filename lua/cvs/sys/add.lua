local function cvs_add(file)
  local cmd = string.format('cvs add "%s"', file)
  local out = vim.fn.system(cmd)
  if vim.v.shell_error > 0 then
    error(out)
  end
end

return function (name)
  cvs_add(name)
end

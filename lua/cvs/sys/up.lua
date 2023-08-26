local function cvs_up(file, rev)
  local cmd = string.format('cvs -nq up -p -r %s "%s"', rev, file)
  local body = vim.fn.systemlist(cmd)
  if vim.v.shell_error > 0 then
    error(body[0])
  end
  return body
end

return function (file, rev)
  local body = cvs_up(file, rev)
  return {
    file = file,
    rev = rev,
    head = {},
    body = body,
  }
end


local function cvs_up(file, rev)
  local cmd = string.format('cvs -nq up -p -r %s "%s"', rev, file)
  local result = vim.fn.system(cmd)
  if vim.v.shell_error > 0 then
    error(result)
  end
  return result
end

local function parse(out, file, rev)
  local body = vim.split(out, '\n')
  -- remove nl at the end
  body[#body] = nil
  return {
    file = file,
    head = {},
    rev = rev,
    body = body,
  }
end

return function (file, rev)
  local out = cvs_up(file, rev)
  local result = parse(out, file, rev)
  return result
end

local make_args = require('cvs.utils.make_args')

local function cvs_annotate(file, opts)
  local cmd = string.format('cvs annotate %s 2>/dev/null', table.concat({
    make_args(opts.rev, '-r'),
    make_args({file}),
  }, ' '))
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error > 0 then
    error('cvs annotate failed: ' .. cmd)
  end
  return out
end

local function parse(lines)
  local result = {}
  for _, line in ipairs(lines) do
    rev, author, date, text = string.match(line, '([%d%.]+)%s+%((%w+)%s+(%d%d%-%w%w%w%-%d%d)%): (.*)')
    if not rev then
      error('cvs annotate parse failed: ' .. line)
    end
    table.insert(result, {
      rev = rev,
      author = author,
      date = date,
      line = text,
    })
  end
  return result
end

return function (file, opts)
  local out = cvs_annotate(file, opts)
  local result = parse(out)
  return result
end

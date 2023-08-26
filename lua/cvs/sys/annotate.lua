local cvs_log = require('cvs.sys.log')
local make_args = require('cvs.utils.make_args')

local ANNOTATE_PATTERN = '([%d%.]+)%s+%((%w+)%s+(%d%d%-%w%w%w%-%d%d)%): (.*)'

local function combine(annotate, log)
  local function find_commit(rev)
    for _, entry in ipairs(log) do
      for _, commit in ipairs(entry.commits) do
        if commit.rev == rev then
          return commit
        end
      end
    end
  end
  return vim.tbl_map(function (entry)
    local commit = find_commit(entry.rev)
    return {
      rev = entry.rev,
      author = commit and commit.author or entry.author,
      date = entry.date,
      ts = commit and commit.ts or nil,
      line = entry.line,
      commit = commit,
    }
  end, annotate)
end

local function cvs_annotate(file, opts)
  local cmd = string.format('cvs annotate %s 2>/dev/null', table.concat({
    make_args({opts.rev}, '-r'),
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
    local rev, author, date, text = string.match(line, ANNOTATE_PATTERN)
    assert(rev, 'cvs annotate: parse failed (' .. line .. ')')
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
  local annotate = parse(out)
  local log = cvs_log({ file }, { rev = opts.rev })
  local result = combine(annotate, log)
  return result
end

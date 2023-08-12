local function iterator(tbl)
  local i = 0
  return function ()
    i = i+1
    return tbl[i]
  end
end

local function tokenizer(str)
  return iterator(vim.split(str, '%s+'))
end

return function (args)
  if #args == 0 then
    return {}, {}
  end
  local tokens = tokenizer(args)
  local files = {}
  local opts = {}
  local opt
  local function read_opt(token, prefix)
    if vim.startswith(token, prefix) then
      if token == prefix then
        opt = tokens()
      else
        opt = string.sub(token, 3)
      end
      return opt
    end
  end
  local function set_opt(name)
    opts[name] = opt
    opt = nil
    return true
  end
  local function push_opt(name)
    if opts[name] then
      table.insert(opts[name], opt)
    else
      opts[name] = {opt}
    end
    opt = nil
    return true
  end
  local function push_file(name)
    if name == '%' then
      name = vim.fn.expand(name)
    end
    table.insert(files, name)
  end
  for token in tokens do
    _ =
    read_opt(token, '-C') and set_opt('context') or
    read_opt(token, '-U') and set_opt('context') or
    read_opt(token, '-d') and set_opt('date_range') or
    read_opt(token, '-A') and push_opt('author') or
    read_opt(token, '-r') and push_opt('rev') or
    read_opt(token, '-D') and push_opt('date') or
    push_file(token)
  end
  return files, opts
end


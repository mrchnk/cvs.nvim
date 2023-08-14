local function tokenizer(str)
  local letters = vim.gsplit(str, '')
  local function read_until(last, strict)
    local res = ''
    for letter in letters do
      if letter == last then
        return res
      else
        res = res .. letter
      end
    end
    if strict then
      error(string.format('Malformed arguments: %s missing', last))
    end
    return res
  end
  return function ()
    for letter in letters do
      if letter == '"' or letter == "'" then
        return read_until(letter, true)
      elseif letter ~= ' ' then
        return letter .. read_until(' ')
      end
    end
  end
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
    return true
  end
  local function push_opt(name, template)
    local value = template and string.format(template, opt) or opt
    if opts[name] then
      table.insert(opts[name], value)
    else
      opts[name] = {value}
    end
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
    read_opt(token, '-r') and push_opt('rev') and push_opt('rev_date', '-r "%s"') or
    read_opt(token, '-D') and push_opt('date') and push_opt('rev_date', '-D "%s"') or
    push_file(token)
  end
  return files, opts
end


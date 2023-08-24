local ns = 0

local id = {
  author = 'CVSAuthor',
  status = 'CVSStatus',
  annotate = {},
  annotate_fg = {},
}

local _autocmd

local function gradient(clr1, clr2, lambda)
  local clr = {}
  for i = 1, 3 do
    clr[i] = math.floor(clr1[i] * (1-lambda) + clr2[i] * lambda)
  end
  return clr
end

local function clr_str(clr)
  return string.format('#%02x%02x%02x', unpack(clr))
end

local function _get_annotate(tbl, temp)
  local size = #tbl
  if size == 0 then
    return nil
  else
    local idx = 1 + math.floor(size * temp + 0.5)
    if idx < 1 then
      return tbl[1]
    elseif idx > size then
      return tbl[size]
    else
      return tbl[idx]
    end
  end
end

local function get_annotate(temp)
  return _get_annotate(id.annotate, temp)
end

local function get_annotate_fg(temp)
  return _get_annotate(id.annotate_fg, temp)
end

local function _setup(opts)
  opts = opts or {}
  vim.api.nvim_set_hl(ns, id.author, { link = 'Constant' })
  vim.api.nvim_set_hl(ns, id.status, opts.status or { link = 'Keyword' })
  local cold_clr = {0, 0, 255}
  local hot_clr = {255, 0, 0}
  for i = 1, 100 do
    local clr = clr_str(gradient(cold_clr, hot_clr, (i-1)/99))
    local annotate_id = string.format('CVSAnnotate_%02d', i-1)
    local annotate_fg_id = string.format('CVSAnnotateFg_%02d', i-1)
    vim.api.nvim_set_hl(ns, annotate_id, { bg = clr, fg = 'White' })
    vim.api.nvim_set_hl(ns, annotate_fg_id, { fg = clr })
    id.annotate[i] = annotate_id
    id.annotate_fg[i] = annotate_fg_id
  end
end

local function setup(opts)
  _setup(opts)
  if _autocmd then
    vim.api.nvim_del_autocmd(_autocmd)
  end
  _autocmd = vim.api.nvim_create_autocmd('ColorScheme', {
    callback = function ()
      _setup(opts)
    end,
  })
end

return {
  ns = ns,
  id = id,
  get_annotate = get_annotate,
  get_annotate_fg = get_annotate_fg,
  setup = setup,
}

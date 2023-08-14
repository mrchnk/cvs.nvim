local sorters = require('telescope.sorters')
local fzy = require('telescope.algos.fzy')
local some_str_find = require('cvs.util.some_str_find')
local OFFSET = -fzy.get_score_floor()

local function scoring_fn(self, prompt, line, entry)
  if not fzy.has_match(prompt, line) then
    return 1
  end
  local fzy_score = fzy.score(prompt, line)
  if fzy_score == fzy.get_score_min() then
    return 1
  end
  return 1 / (fzy_score + OFFSET)
end

local function match_entry(prompt, entry)
  local lo_prompt = string.lower(prompt)
  local file = entry.value.file
  local body = entry.value.body
  for word in vim.gsplit(lo_prompt, '%s+', {trimempty=true}) do
    local found = some_str_find(word, body, 4) or
      fzy.has_match(word, file)
    if not found then
      return false
    end
  end
  return true
end

local function filter_fn(self, prompt, entry)
  if #prompt == 0 then
    return 1, prompt
  end
  local match = match_entry(prompt, entry)
  return match and 1 or -1, prompt
end

local function highlighter(_, prompt, display)
  local highlights = {}
  -- every display begins with status symbol + space
  local file = string.sub(display, 3)
  for _, pos in ipairs(fzy.positions(prompt, file)) do
    table.insert(highlights, pos+2)
  end
  return highlights
end

return function ()
  return sorters.Sorter:new{
    scoring_function = scoring_fn,
    filter_function = filter_fn,
    highlighter = highlighter,
  }
end


local sorters = require('telescope.sorters')
local fzy = require('telescope.algos.fzy')
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

local function _find_word(word, body)
  for i, line in ipairs(body) do
    if i > 3 and string.find(string.lower(line), word) then
      return true
    end
  end
  return false
end

local function _match_diff(prompt, body)
  for word in vim.gsplit(string.lower(prompt), '%s+', {trimempty=true}) do
    if not _find_word(word, body) then
      return false
    end
  end
  return true
end

local function filter_fn(self, prompt, entry)
  if #prompt == 0 then
    return 1, prompt
  end
  local file = entry.value.file
  local body = entry.value.body
  local match = fzy.has_match(prompt, file) or
    _match_diff(prompt, body)
  return match and 1 or -1, prompt
end

local function highlighter(_, prompt, display)
  local highlights = {}
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


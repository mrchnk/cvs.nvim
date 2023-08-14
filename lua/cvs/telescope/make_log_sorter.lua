local sorters = require('telescope.sorters')
local find_words = require('cvs.util.find_words')
local some_str_find = require('cvs.util.some_str_find')
local some_fzy_match = require('cvs.util.some_fzy_match')

local function scoring_fn(self, prompt, ordinal, entry)
  return 1/entry.value.ts
end

local function match_entry(prompt, entry)
  local lo_prompt = string.lower(prompt)
  local message = entry.value.message
  local files = entry.value.files
  local lo_author = string.lower(entry.value.author)
  for word in vim.gsplit(lo_prompt, '%s+', {trimempty=true}) do
    local found = word == lo_author or
      some_str_find(word, message) or
      some_fzy_match(word, files)
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
  if #prompt > 0 then
    local lo_display = string.lower(display)
    local lo_prompt = string.lower(prompt)
    for pos, len in find_words(lo_prompt, lo_display) do
      table.insert(highlights, {
        start = pos,
        finish = pos + len - 1,
      })
    end
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


local sorters = require('telescope.sorters')
local fzy = require('telescope.algos.fzy')

local function scoring_fn(self, prompt, ordinal, entry)
  return 1/entry.value.ts
end

local function find_word(word, message)
  for _, line in ipairs(message) do
    if string.find(string.lower(line), word) then
      return true
    end
  end
  return false
end

local function match_message(prompt, message)
  for word in vim.gsplit(string.lower(prompt), '%s+', {trimempty=true}) do
    if not find_word(word, message) then
      return false
    end
  end
  return true
end

local function match_files(prompt, files)
  for _, file in ipairs(files) do
    if fzy.has_match(prompt, file.file) then
      return true
    end
  end
  return false
end

local function filter_fn(self, prompt, entry)
  if #prompt == 0 then
    return 1, prompt
  end
  local message = entry.value.message
  local files = entry.value.files
  local author = entry.value.author
  local match = prompt == author or
    match_message(prompt, message) or
    match_files(prompt, files)
  return match and 1 or -1, prompt
end


local function highlighter(_, prompt, display)
  local highlights = {}
  local lo_display = string.lower(display)
  for word in vim.gsplit(string.lower(prompt), '%s+', {trimempty=true}) do
    local start, finish = string.find(lo_display, word, 1, true)
    if start then
      table.insert(highlights, { start = start, finish = finish })
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


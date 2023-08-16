local fzy = require('telescope.algos.fzy')
local find_words = require('cvs.util.find_words')
local make_buf_previewer = require('cvs.telescope.make_buf_previewer')

local function get_max_file_len(files)
  local m = 1
  for _, file in ipairs(files) do
    local file_len = #file.file
    if file_len > 99 then
      return 99
    elseif file_len > m then
      m = file_len
    end
  end
  return m
end

local function format_entry(entry, prompt)
  local author = entry.value.author
  local date = entry.value.date
  local message = entry.value.message
  local files = entry.value.files
  local lo_prompt = string.lower(prompt)
  local lo_author = string.lower(author)
  local lines = {
    string.format('Author: %s', author),
    string.format('Date:   %s', date),
    '',
  }
  local matches = {}
  for word in vim.gsplit(lo_prompt, '%s+', {trimempty=true}) do
    if word == lo_author then
      table.insert(matches, {1, 9, #word})
    end
    local pos = string.find(date, word, 1, true)
    if pos then
      table.insert(matches, {2, 8 + pos, #word})
    end
  end
  for _, line in ipairs(message) do
    table.insert(lines, '    ' .. line)
    local lo_line = string.lower(line)
    if #prompt > 0 then
      for pos, len in find_words(lo_prompt, lo_line) do
        table.insert(matches, {#lines, pos+4, len})
      end
    end
  end
  table.insert(lines, '')
  local max_file_len = get_max_file_len(files)
  for _, file in ipairs(files) do
    table.insert(lines, string.format('  %-' .. max_file_len .. 's  -r%s', file.file, file.rev))
    if #prompt > 0 then
      for word in vim.gsplit(lo_prompt, '%s+', {trimempty = true}) do
        for _, pos in ipairs(fzy.positions(word, file.file)) do
          table.insert(matches, {#lines, pos+2, 1})
        end
      end
    end
  end
  table.insert(lines, string.format('  %s file(s) changed', #files))
  return lines, matches
end

return function ()
  return make_buf_previewer{
    format_entry = format_entry,
  }
end


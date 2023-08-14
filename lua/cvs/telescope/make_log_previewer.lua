local make_buf_previewer = require('cvs.telescope.make_buf_previewer')
local fzy = require('telescope.algos.fzy')

local function find_words(prompt, line)
  local words = vim.gsplit(prompt, '%s+', {trimempty=true})
  local word = words()
  local pos = 0
  return function ()
    while word do
      pos = string.find(line, word, pos+1)
      if pos then
        return pos, #word
      end
      word = words()
      pos = 0
    end
  end
end

local function format_entry(entry, prompt)
  local author = entry.value.author
  local date = entry.value.date
  local message = entry.value.message
  local files = entry.value.files
  local lines = {
    string.format('Author: %s', author),
    string.format('Date:   %s', date),
    '',
  }
  local matches = {}
  if prompt == author then
    table.insert(matches, {1, 9, #author})
  end
  for _, line in ipairs(message) do
    table.insert(lines, '    ' .. line)
    for pos, len in find_words(prompt, line) do
      table.insert(matches, {#lines, pos+4, len})
    end
  end
  table.insert(lines, '')
  local max_file_len = math.max(unpack(vim.tbl_map(function (file)
    return #file.file
  end, files)))
  for _, file in ipairs(files) do
    table.insert(lines, string.format('  %-' .. max_file_len .. 's  -r%s', file.file, file.rev))
    for _, pos in ipairs(fzy.positions(prompt, file.file)) do
      table.insert(matches, {#lines, pos+2, 1})
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

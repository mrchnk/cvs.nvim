local fzy = require('telescope.algos.fzy')
local find_words = require('cvs.utils.find_words')

local function get_max_file_len(files)
  local len = 1
  for _, file in ipairs(files) do
    local file_len = #file.file
    if file_len > 99 then
      return 99
    elseif file_len > len then
      len = file_len
    end
  end
  return len
end

return function (commit, prompt)
  local author = commit.author
  local date = commit.date
  local message = commit.message
  local files = commit.files
  local lo_prompt = prompt and string.lower(prompt)
  local lines = {
    string.format('Author: %s', author),
    string.format('Date:   %s', date),
    '',
  }
  local matches = prompt and {}
  if prompt and #prompt > 0 then
    local lo_author = string.lower(author)
    for word in vim.gsplit(lo_prompt, '%s+', {trimempty=true}) do
      if word == lo_author then
        table.insert(matches, {1, 9, #word})
      end
      local pos = string.find(date, word, 1, true)
      if pos then
        table.insert(matches, {2, 8 + pos, #word})
      end
    end
  end
  for _, line in ipairs(message) do
    table.insert(lines, '    ' .. line)
    if prompt and #prompt > 0 then
      local lo_line = string.lower(line)
      for pos, len in find_words(lo_prompt, lo_line) do
        table.insert(matches, {#lines, pos+4, len})
      end
    end
  end
  if files then
    table.insert(lines, '')
    local max_file_len = get_max_file_len(files)
    for _, file in ipairs(files) do
      table.insert(lines, string.format('  %-' .. max_file_len .. 's  -r%s', file.file, file.rev))
      if prompt and #prompt > 0 then
        for word in vim.gsplit(lo_prompt, '%s+', {trimempty = true}) do
          if fzy.has_match(word, file.file) then
            for _, pos in ipairs(fzy.positions(word, file.file)) do
              table.insert(matches, {#lines, pos+2, 1})
            end
          end
        end
      end
    end
    table.insert(lines, string.format('  %s file(s) changed', #files))
  end
  return lines, matches
end


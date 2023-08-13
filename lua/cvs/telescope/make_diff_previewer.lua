local make_buf_previewer = require('cvs.telescope.make_buf_previewer')

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
  local matches = {}
  if #prompt > 0 then
    for i, line in ipairs(entry.value.body) do
      if i > 3 then
        for pos, len in find_words(prompt, line) do
          table.insert(matches, {i, pos, len})
        end
      end
    end
  end
  return entry.value.body, matches
end

return function ()
  return make_buf_previewer{
    setup_buf = function (buf)
      vim.api.nvim_buf_set_option(buf, 'syntax', 'diff')
    end,
    format_entry = format_entry,
  }
end

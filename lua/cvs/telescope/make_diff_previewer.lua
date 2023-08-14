local make_buf_previewer = require('cvs.telescope.make_buf_previewer')
local find_words = require('cvs.util.find_words')

local function setup_buf(buf)
  vim.api.nvim_buf_set_option(buf, 'syntax', 'diff')
end

local function format_entry(entry, prompt)
  local matches = {}
  if #prompt > 0 then
    local body = entry.value.body
    local lo_prompt = string.lower(prompt)
    for i = 3, #body do
      local lo_line = string.lower(body[i])
      for pos, len in find_words(lo_prompt, lo_line) do
        table.insert(matches, {i, pos, len})
      end
    end
  end
  return entry.value.body, matches
end

return function ()
  return make_buf_previewer{
    setup_buf = setup_buf,
    format_entry = format_entry,
  }
end


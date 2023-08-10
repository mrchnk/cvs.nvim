local fzy = require('telescope.algos.fzy')

local function match(diff_entry, prompt)
  if not prompt or prompt == "" then
    return true
  end
  local file_match = fzy.has_match(prompt, diff_entry.file)
  local matches = {}
  for row, line in ipairs(diff_entry.body) do
    local col = string.find(line, prompt, 2)
    if col then
      table.insert(matches, {row, col, string.len(prompt)})
    end
  end
  return file_match or #matches > 0, matches
end

local function make_entry(diff_entry, matches)
  return {
    value = diff_entry,
    filename = diff_entry.file,
    ordinal = diff_entry.file,
    display = diff_entry.file,
    matches = matches,
  }
end

return function (diff_results)
  return setmetatable({
    close = function () end,
  }, {
    __call = function (_, prompt, process_result, process_complete)
      for _, diff_entry in ipairs(diff_results) do
        local m, matches = match(diff_entry, prompt)
        if m then
          process_result(make_entry(diff_entry, matches))
        end
      end
      process_complete()
    end,
  })
end

local function log(msg)
  -- 
end

local function err(msg)
  vim.api.nvim_err_writeln('CVS: ' .. msg)
end

return setmetatable({
  log = log,
  err = err,
}, {
  __call = function (self, msg) log(msg) end
})

return function (v1, v2)
  
  local function test_equals(_v1, _v2)
    if (_v1 ~= _v2) then
      vim.print(v1, 'expected to be', v2)
      error('not equals')
    end
  end

  local function test_deep_equals(v1, v2)
    test_equals(type(v1), type(v2))
    if type(v1) == 'table' then
      for _, t in ipairs({v1, v2}) do
        for k, _ in pairs(t) do
          test_deep_equals(v1[k], v2[k])
        end
      end
    else
      test_equals(v1, v2)
    end
  end

  return test_deep_equals(v1, v2)
end

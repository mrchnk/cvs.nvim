local _conf

local function get_conf(key)
  if key then
    return _conf and _conf[key] or {}
  else
    return _conf or {}
  end
end

local function setup(conf)
  _conf = conf
end

return {
  setup = setup,
  get_conf = get_conf,
}

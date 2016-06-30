--Credits for this lib go to https://github.com/vilu85
configLib = {}
local fs = require("filesystem")
function configLib.loadConfig(cfgFile, defaultCfg)
  -- Try to load user settings.
  local env = {}
  local config = loadfile("/etc/" .. cfgFile, nil, env)
  if config then
    pcall(config)
  end
  -- Fill in defaults.
  env = env or defaultCfg
  -- Generate config file if it didn't exist.
  if not config then
    local root = fs.get("/")
    if root and not root.isReadOnly() then
      fs.makeDirectory("/etc")
      local f = io.open("/etc/" .. cfgFile, "w")
      if f then
        local serialization = require("serialization")
        for k, v in pairs(defaultCfg) do
          f:write(k .. "=" .. tostring(serialization.serialize(v, math.huge)) .. "\n")
        end
        f:close()
      end
    end
    env = defaultCfg
  end
  return env
end

---
-- Saves given config by overwriting/creating given file
-- Returns saved config
function configLib.saveConfig(configFile, config)
  if config then
    local root = fs.get("/")
    if root and not root.isReadOnly() then
      fs.makeDirectory("/etc")
      local f = io.open("/etc/" .. configFile, "w")
      if f then
        local serialization = require("serialization")
        for k, v in pairs(config) do
          f:write(k .. "=" .. tostring(serialization.serialize(v, math.huge)) .. "\n")
        end
        f:close()
      end
    end
  end
  return config
end
return configLib
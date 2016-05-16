local component = require("component")
local computer  = require("computer")
local modem     = require("modem")
local configlib = require("configlib")
local conf      = configlib.loadConfig('lights.cfg', {})
function listLights(conf)
  local li = 1
  if (conf.lights ~= nil) then 
    for k,v in pairs(conf.lights) do
      print(li.." => "..k)
      li = li + 1
    end
  else
    print("Lights are not configured yet")
  end
end

if (component.get("comp") ~= nil) then
  
else
  print("Component not found")
end

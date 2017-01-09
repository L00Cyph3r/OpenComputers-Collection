local component = require("component")
local computer = require("computer")
local serial = require("serialization")
local nav = component.navigation
local modem = component.modem
local internet = component.internet
local robot = require("robot")
local json = require("json")
local configLib = require("config")
local ports = {}
ports["comms"] = 10000
local defaultCfg = {
  serveraddress = "https://example.com/receiver.php"
}
local conf = configLib.loadConfig("atc.cfg",defaultCfg)
modem.open(ports["comms"])
local atc = {}
atc["currentActivity"] = "idle"
atc["currentTarget"] = nil

function atc.getLocation()
  local wps = nav.findWaypoints(500)
  for k,v in ipairs(wps) do
    if string.find(v.label,"{loc={") then
      wploc = serial.unserialize(v.label).loc
      loc = {}
      loc['x'] = wploc.x - v.position[1]
      loc['y'] = wploc.y - v.position[2]
      loc['z'] = wploc.z - v.position[3]
      return {x = loc.x,y=loc.y,z=loc.z}
    end
  end
  if loc ~= nil then
    atc.sendStatus()
    return loc
  else
    return false
  end
end
function atc.sendStatus()
  local post_data = {}
  local stat = {}
  stat["location"] = atc.getLocation()
  stat["computer"] = {}
  stat["computer"]["energy"] = computer.energy()
  stat["computer"]["maxEnergy"] = computer.maxEnergy()
  stat["computer"]["freeMemory"] = computer.freeMemory()
  stat["computer"]["totalMemory"] = computer.totalMemory()
  stat["computer"]["uptime"] = computer.uptime()
  stat["robot"] = {}
  stat["robot"]["lightColor"] = robot.getLightColor()
  stat["robot"]["activity"] = atc["currentActivity"]
  stat["robot"]["name"] = robot.name()
  stat["robot"]["level"] = robot.level()
  stat["robot"]["currentTarget"] = atc["currentTarget"]
  post_data["type"] = "status"
  post_data["from"] = modem.address
  post_data["message"] = stat
  internet.request(conf.serveraddress, json:encode(post_data))
end

function atc.setActivity(stat)
  atc["currentActivity"] = stat
end
function atc.setCurrentTarget(x,y,z)
  atc["currentTarget"] = {x=x,y=y,z=z}
end
function atc.clearCurrentTarget()
  atc["currentTarget"] = {}
end
function atc.getCurrentTarget()
  return atc["currentTarget"]
end
function atc.getActivity()
  return atc["currentActivity"]
end
return atc

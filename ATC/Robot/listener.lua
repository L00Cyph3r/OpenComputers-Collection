local component = require("component")
local computer = require("computer")
local modem = component.modem
local event = require("event")
local serial = require("serialization")
local shell = require("shell")
local wp = require("wp")
local atc = require("atc")
local configLib = require("config")
local ports = {}
ports["comms"] = 10000
local defaultCfg = {
  serveraddress = "http://exampleserver.com/receiver.php"
}
local conf = configLib.loadConfig("/etc/atc.cfg",defaultCfg)
modem.close(ports["comms"])
if modem.open(ports["comms"]) == true then
else
  print("Could not open port: "..port["comms"])
  os.exit()
end

local function signal(_,_,from,_,_,message)
  local post_data = {}
  post_data["from"] = modem.address
  local msg = serial.unserialize(message)
  if msg["type"] == "command" then
    print("Executing: " .. msg["command"])
    shell.execute(msg["command"])
  elseif msg["type"] == "route" then
    for k,v in pairs(msg["route"]) do
      wp.goTo(v)
    end
  elseif msg["type"] == "coords" then
    wp.gotoWaypoint(msg["coords"].x,msg["coords"].y,msg["coords"].z)
  elseif msg["type"] == "location" then
    print("sending status-update")
    atc.sendStatus()
    print("status-update sent")
  end
end

local function gotowp(route)
  for k,v in pairs(route) do
    wp.goTo(v)
  end
end
event.listen("modem_message", signal)

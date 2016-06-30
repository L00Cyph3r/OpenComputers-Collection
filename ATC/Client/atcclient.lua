local component = require("component")
local computer = require("computer")
local modem = component.modem
local event = require("event")
local serial = require("serialization")
local filesystem = require("filesystem")
local internet = component.internet
local shell = require("shell")
local term = require("term")
local json = require("json")
local interface = require("interface")
local configLib = require("config")
local gpu = component.gpu
local w,h = gpu.getResolution()
local numrobots = 0
local defaultCfg = {
  serveraddress = "http://exampleserver.com/receiver.php"
}
local conf = configLib.loadConfig("atcclient.cfg",defaultCfg)
local function downloadLatest()
  local url = conf.serveraddress
  local success, response = pcall(component.internet.request, url)
  if success then
    local resdata = ""
    while true do
      local data, responseChunk = response.read()
      if data then
        resdata = resdata .. data
      else
        if responseChunk then
          return false, responseChunk
        else
          return true, resdata
        end
      end
    end
  else
    return false, reason
  end
end

local function robotRefresh(address)
  modem.send(address,10000, serial.serialize({type="location"}))
end

local function robotDelete(address)
  local url = conf.serveraddress
  local post_data = {}
  
  post_data["type"] = "robotDelete"
  post_data["address"] = address
  internet.request(url, json:encode(post_data))
  print("Remove robot from server...")
  os.sleep(3)
  interface.clearAllObjects()
end

local function robotGoto(address)
  term.clear()
  term.write("Enter X-coordinate: ")
  local x = term.read()
  term.write("Enter Y-coordinate: ")
  local y = term.read()
  term.write("Enter Z-coordinate: ")
  local z = term.read()
  if (x ~= nil and y ~= nil and z ~= nil) then
    print("Sending robot to: \nX: "..tonumber(x).." Y: "..tonumber(y).." Z: "..tonumber(z))
    modem.send(address,10000, serial.serialize({type="coords",coords={x=x,y=y,z=z}}))
    os.sleep(2)
  end
  screenOverview()
end

function screenOverview()
  interface.newLabel("s1-screentitle","Robots",1,1,10,1,0x000000)
  local ret,robots = downloadLatest()
  if ret ~= false then
    robots = json:decode(robots)
    if #robots ~= numrobots then
      numrobots = #robots
      interface.clearAllObjects()
    end
    local yoffset = 2
    if ret == true then
      for k,v in ipairs(robots) do
        yoffset = yoffset + 1
        interface.newLabel("s1-robot-"..k.."-name",v.modem_addr,3,yoffset,36, 1,0x000000,0x00FF00)
        interface.newButton("s1-robot-"..k.."-refresh", "Update", (w - (string.len("Update") + 2)),yoffset,(string.len("Update") + 2),1,robotRefresh,v.modem_addr,0x00FF00,0xFF0000, 1)
        interface.newButton("s1-robot-"..k.."-goto", "GoTo", (w - (string.len("GoTo    Update") + 2)),yoffset,(string.len("GoTo") + 2),1,robotGoto,v.modem_addr,0x00FF00,0xFF0000, 1)
        interface.newButton("s1-robot-"..k.."-robotDelete", "Delete", (w - (string.len("Delete    GoTo    Update") + 2)),yoffset,(string.len("Delete") + 2),1,robotDelete,v.modem_addr,0x00FF00,0xFF0000, 1)
        
        yoffset = yoffset + 1
        interface.newLabel("s1-robot-"..k.."-batterylabel","Battery  "..v.status.computer.batteryperc.."%",3,yoffset,string.len("Battery  "..v.status.computer.batteryperc.."%"),1,0x000000,0xFFFFFF)
        interface.newBar("s1-robot-"..k.."-batterybar",20,yoffset,w - 20, 1,0x00FF00,0xFF0000,v.status.computer.batteryperc)
        
        yoffset = yoffset + 1 
        interface.newLabel("s1-robot-"..k.."-memorylabel", "Memory   "..v.status.computer.memoryperc.."%",3,yoffset,string.len("Memory   "..v.status.computer.memoryperc.."%"),1,0x000000,0xFFFFFF)
        interface.newBar("s1-robot-"..k.."-memorybar",20,yoffset,w - 20, 1,0x00FF00,0xFF0000,v.status.computer.memoryperc)
        
        yoffset = yoffset + 1 
        interface.newLabel("s1-robot-"..k.."-activitylabel","Activity: ",3,yoffset,string.len("Activity: "),1,0x000000,0xFFFFFF)
        interface.newLabel("s1-robot-"..k.."-activity",v.status.robot.activity,20,yoffset,string.len(v.status.robot.activity),1,0x000000,0xFFFFFF)
        if v.status.location ~= false then
          yoffset = yoffset + 1 
          interface.newLabel("s1-robot-"..k.."-xyzlabel","X-Y-Z",3,yoffset,string.len("X-Y-Z"),1,0x000000,0xFFFFFF)
          interface.newLabel("s1-robot-"..k.."-xyz","X("..v.status.location.x..") Y("..v.status.location.y..") Z("..v.status.location.z..")",20,yoffset,string.len("X("..v.status.location.x..") Y("..v.status.location.y..") Z("..v.status.location.z..")"),1,0x000000,0xFFFFFF)
        end
        --      print("  X: " .. v.status.location.x .. "  Z: " .. v.status.location.z .. "  Y: " .. v.status.location.y .."    Energy: " .. v.status.computer.batteryperc .."%    Free Mem: " .. v.status.computer.memoryperc .. "%")
        yoffset = yoffset + 2
      end
    end
  end
  interface.updateAll()
end
interface.clearAllObjects()
interface.clearScreen()
gpu.setBackground(0x000000)
local ticks = 0
while true do
  if ticks % 5 == 0 then
    --interface.clearAllObjects()
    screenOverview()
  end
  local _,_,x,y = event.pull(1,"touch")
  if x and y then
    interface.processClick(x,y)
  end
  ticks = ticks + 1
end

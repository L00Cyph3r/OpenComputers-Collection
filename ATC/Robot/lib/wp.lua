--[[
Great thanks to Dustpuppy for his tremendously helpfull library which I modified
in here. Original can be found here:
https://oc.cil.li/index.php?/topic/942-waypoint-library-for-robots/
]]
local component = require("component")
local robot = require("robot")
local computer = require("computer")
local serial = require("serialization")
local package = require("package")
local atc = require("atc")
local nav = component.navigation
local wp = {}
local lightError  = 0xFF0000		-- error = red
local lightIdle   = 0x0000FF		-- idle = blue
local lightCharge = 0xFFFFFF		-- charging = white
local lightMove   = 0x00FF00		-- moving = green
local lightWork   = 0xFFFF00		-- working = yellow (dig, drop, suck, etc.)
local lightBusy   = 0xFF00FF		-- busy = magenta
local scanRange = 512
local autoCharge = false
local autoChargeValue = 0.25
local autoCharger = "autocharger"
local function errorReport(msg)
  robot.setLightColor(lightError)
  io.stderr:write("[ERROR] " .. msg .. "\n")
end
local facingTable = {}
facingTable[1] = "facings"
facingTable[2] = "north"
facingTable[3] = "south"
facingTable[4] = "west"
facingTable[5] = "east"
local yPosition = 0 
local function face(direction)
  robot.setLightColor(lightMove)
  while facingTable[nav.getFacing()] ~= direction do
    robot.turnRight()
  end
  robot.setLightColor(lightIdle)
end
function wp.getAutoCharge()
  return autoCharge
end
function wp.enableAutoCharge(value)
  autoCharge = value
end
function wp.getAutoCharger()
  return autoCharger
end
function wp.setAutoCharger(value)
  autoCharger = value
end
function wp.getScanRange()
  return scanRange
end
function wp.setScanRange(value)
  scanRange = value
end
function wp.gotoWaypoint(x,y,z,f)
  local targetX = x
  local targetY = y
  local targetZ = z
  robot.setLightColor(lightBusy)
  atc.setCurrentTarget(x,y,z)
  local newPos = wp.getLocation()
  while(newPos.x ~= targetX or newPos.y ~= targetY or newPos.z ~= targetZ) do
    print("Going to: " .. targetX .. " " .. targetY .. " " .. targetZ)
    local curloc = wp.getLocation()
    x = targetX - curloc.x
    y = targetY - curloc.y
    z = targetZ - curloc.z
    local steps = 0
    if yPosition < y then
      atc.setActivity("departure")
      atc.sendStatus()
      robot.setLightColor(lightMove)
      steps = math.floor(y) -yPosition
      for i=1, steps do
        if i % 100 == 0 then
          atc.sendStatus()
        end
        robot.up()
        yPosition = yPosition + 1;
      end
      robot.setLightColor(lightIdle)
    end
    steps = math.abs(x)
    if x > 0 then
      atc.setActivity("cruising")
      atc.sendStatus()
      robot.setLightColor(lightMove)
      face("east")
      for i=1, steps do
        if i % 10 == 0 then
          os.sleep(0.05)
        end
        robot.forward()
      end
      robot.setLightColor(lightIdle)
      atc.setActivity("idle")
    elseif x < 0 then
      atc.setActivity("cruising")
      atc.sendStatus()
      robot.setLightColor(lightMove)
      face("west")
      for i=1, steps do
        if i % 10 == 0 then
          os.sleep(0.05)
        end
        if robot.forward() == true then
        else
          i = i - 1
          for u=1, 4 do
            robot.up()
          end
          robot.forward()
          robot.forward()
          for u=1, 4 do
            robot.down()
          end
          i = i + 2
        end
      end
      robot.setLightColor(lightIdle)
      atc.setActivity("idle")
    end
    steps = math.abs(z)
    if z > 0 then
      atc.setActivity("cruising")
      atc.sendStatus()
      face("south")
      robot.setLightColor(lightMove)
      for i=1, steps do
        if i % 10 == 0 then
          os.sleep(0.05)
        end
        if robot.forward() == true then
        else
          i = i - 1
          for u=1, 4 do robot.up() end
          robot.forward()
          robot.forward()
          for u=1, 4 do
            robot.down()
          end
          i = i + 2
        end
      end
      robot.setLightColor(lightIdle)
      atc.setActivity("idle")
    elseif z < 0 then
      atc.setActivity("cruising")
      atc.sendStatus()
      robot.setLightColor(lightMove)
      face("north")
      for i=1, steps do
        if i % 100 == 0 then
          atc.sendStatus()
        end
        if robot.forward() == true then
        else
          i = i - 1
          for u=1, 4 do robot.up() end
          robot.forward()
          robot.forward()
          for u=1, 4 do
            robot.down()
          end
          i = i + 2
        end
      end
      robot.setLightColor(lightIdle)
      atc.setActivity("idle")
    end
    atc.setActivity("arrival")
    atc.sendStatus()
    if yPosition > y then
      robot.setLightColor(lightMove)
      steps = yPosition - math.floor(y)
      for i=1, steps do
        if i % 100 == 0 then
          atc.sendStatus()
        end
        robot.down()
      end
      robot.setLightColor(lightIdle)
      atc.setActivity("idle")
    elseif yPosition < y then
      robot.setLightColor(lightMove)
      steps = math.floor(y) -yPosition
      for i=1, steps do
        if i % 100 == 0 then
          atc.sendStatus()
        end
        robot.up()
      end
      robot.setLightColor(lightIdle)
      atc.setActivity("idle")
    end
    yPosition = 0
    newPos = wp.getLocation()
    print("newPos: " .. newPos.x .. " " ..newPos.y .. " ".. newPos.z)
    print("target: " .. targetX .. " " .. targetY .. " " .. targetZ)
    if f then
      face(f)
    end
  end
  atc.setActivity("idle")
  robot.setLightColor(lightIdle)
  atc.clearCurrentTarget()
  atc.sendStatus()
end
function wp.getLocation()
  local wps = nav.findWaypoints(scanRange)
  if #wps > 0 then
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
  else
    return false
  end
  if loc ~= nil then
    return loc
  else
    return false
  end
end
function wp.goTo(name,f)
  if autoCharge == true then
    if computer.energy() < (computer.maxEnergy()*autoChargeValue) then
      wp.gotoWaypoint(autoCharger)
      robot.setLightColor(lightCharge)
      while computer.energy() < (computer.maxEnergy()*0.95) do		-- autocharge until 95% full
        os.sleep(1)
      end
      robot.setLightColor(lightIdle)
    end
  end
  local w = nav.findWaypoints(scanRange)
  if w == nil then
    errorReport("Way point " .. name .. " not found")
    return false
  end
  local x,y,z
  local curloc = wp.getLocation()
  for k,v in pairs(w) do
    if k ~= "n" then
      if v.label == name then
        x = math.floor(v.position[1]) + curloc.x
        y = math.floor(v.position[2]) + 1 + curloc.y -- offset to go above WP
        z = math.floor(v.position[3]) + curloc.z
      end
    end
  end
  return wp.gotoWaypoint(x,y,z,f)
end
return wp
local component = require("component")
local robot = require("robot")
local computer = require("computer")
local nav = component.navigation

local wp = {}

-- color codes for the light
local lightError  = 0xFF0000		-- error = red
local lightIdle   = 0x0000FF		-- idle = blue
local lightCharge = 0xFFFFFF		-- charging = white
local lightMove   = 0x00FF00		-- moving = green
local lightWork   = 0xFFFF00		-- working = yellow (dig, drop, suck, etc.)
local lightBusy   = 0xFF00FF		-- busy = magenta

-- the range that is used for finding findWaypoints
local scanRange = 512

-- by default robot will not auto charge 
local autoCharge = false
-- percentage robot will go to charger
local autoChargeValue = 0.25
-- stores name of the waypoint with charger for auto charging
local autoCharger = "autocharger"

-- Function writes an error message to stderr and changes the robot light to red
local function errorReport(msg)
  robot.setLightColor(lightError)
  io.stderr:write("[ERROR] " .. msg .. "\n")
end

--robot.setLightColor(lightBusy)

-- get the direction robot is looking
--2 north
--3 south
--4 west
--5 east
local facingTable = {}
facingTable[1] = "facings"
facingTable[2] = "north"
facingTable[3] = "south"
facingTable[4] = "west"
facingTable[5] = "east"

-- stores the height the robot is moving
local yPosition = 0 

-- facing the robot into the given position
local function face(direction)
  robot.setLightColor(lightMove)
  while facingTable[nav.getFacing()] ~= direction do
    robot.turnRight()
  end
  robot.setLightColor(lightIdle)
end

-- enables/disables auto charging
function wp.getAutoCharge()
  return autoCharge
end

-- enables/disables auto charging
function wp.enableAutoCharge(value)
  autoCharge = value
end

-- returns name of the waypoint with charger
function wp.getAutoCharger()
  return autoCharger
end

-- set the name of the waypoint used for charging
function wp.setAutoCharger(value)
  autoCharger = value
end

-- Returns the range of findWaypoints
function wp.getScanRange()
  return scanRange
end

-- sets the range of findWaypoints
function wp.setScanRange(value)
  scanRange = value
end

-- moves robot to the given waypoint
local function gotoWaypoint(name, f)
  robot.setLightColor(lightBusy)
  local w = nav.findWaypoints(scanRange)
  if w == nil then
    errorReport("Way point " .. name .. " not found")
    return false
  end
  for k,v in pairs(w) do
    if k ~= "n" then
      if v.label == name then
        x = math.floor(v.position[1])
        y = math.floor(v.position[2]) + 1 -- offset to go above WP
        z = math.floor(v.position[3])
      end
    end
  end
  print("[INFO] moving to " ..name .. " at " .. x .. "," .. y .. "," .. z)
  local steps = 0
  
  -- first the x axis (east - west)
  -- ---------------------------------
  -- calc the steps to moves
  steps = math.abs(x)
  
  if x > 0 then
    robot.setLightColor(lightMove)
    -- getting up first
    -- moving to east
    face("east")
    robot.setLightColor(lightMove)
    for i=1, steps do
      robot.forward()
    end
    robot.setLightColor(lightIdle)
  elseif x < 0 then
    robot.setLightColor(lightMove)
    -- moving to west
    face("west")
    robot.setLightColor(lightMove)
    for i=1, steps do
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
  end
  
  -- second the z axis (north - south)
  -- ---------------------------------
  -- calc the steps to moves
  steps = math.abs(z)
  
  -- set the facing
  if z > 0 then
    robot.setLightColor(lightMove)
    -- moving to south
    face("south")
    robot.setLightColor(lightMove)
    for i=1, steps do
      robot.forward()
    end
    robot.setLightColor(lightIdle)
  elseif z < 0 then
    robot.setLightColor(lightMove)
    -- moving to north
    face("north")
    robot.setLightColor(lightMove)
    for i=1, steps do
      robot.forward()
    end
    robot.setLightColor(lightIdle)
  end
  
  -- at last the height
  -- ---------------------------------
  
  if yPosition > y then
    robot.setLightColor(lightMove)
    steps = yPosition - math.floor(y)
    for i=1, steps do
      robot.down()
    end
    robot.setLightColor(lightIdle)
  elseif yPosition < y then
    robot.setLightColor(lightMove)
    steps = math.floor(y) -yPosition
    for i=1, steps do
      robot.up()
    end
    robot.setLightColor(lightIdle)
  end
  yPosition = 0
  
  -- if facing is set, we have to set it
  if f then
    face(f)
  end
end

-- the real function to move to a given waypoint. sends robot to charger, if autocharging is enabled
function wp.goTo(name,f)
  if autoCharge == true then
    if computer.energy() < (computer.maxEnergy()*autoChargeValue) then
      gotoWaypoint(autoCharger)
      robot.setLightColor(lightCharge)
      while computer.energy() < (computer.maxEnergy()*0.95) do		-- autocharge until 95% full
        os.sleep(0.5)
      end
      robot.setLightColor(lightIdle)
    end
  end
  gotoWaypoint(name,f)
end

return wp
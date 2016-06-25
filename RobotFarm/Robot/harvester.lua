local component = require("component")
local computer = require("computer")
local os = require("os")
local robot = require("robot")
local geo = component.geolyzer
local nav = component.navigation
--local modem = require("modem")
local ic = component.inventory_controller
local sides = require("sides")

local plotsize = {}
plotsize["z"] = 8
plotsize["x"] = 8

local invSlots = {}
invSlots["seeds"] = {1}
invSlots["harvest"] = {2,3,4,5,6,7,8}

-- Waypoint to start at
-- local waypoint = "L00_Cyph3r,garden,wheat,1" --unused
local harvestableMaterials = {}
harvestableMaterials["minecraft:wheat"] = true

local function departFromStart()
  robot.up()
  robot.forward()
  robot.setLightColor(0x00FF00)
end

local function arriveAtStart()
  robot.back()
  robot.down()
  robot.setLightColor(0x00FF00)
end

local function beepStop()
  local beeps = {
    2000,
    1800,
    1600,
    1400,
    1200
  }
  
  for i=1,#beeps do
    computer.beep(beeps[i])
    os.sleep(0.05)
  end
end

local function beepStart()
  local beeps = {
    1200,
    1400,
    1600,
    1800,
    2000
  }
  
  for i=1,#beeps do
    computer.beep(beeps[i])
    os.sleep(0.05)
  end
end

local function checkHarvestable()
  local scan = geo.analyze(sides.down)
  if harvestableMaterials[scan.name] ~= nil then -- if material exists in table
    if scan.growth == 1 then
      return true
    else
      return false
    end
  else
    return "no_seed"
  end
end

local function harvestSpot()
  local harvest_bool = checkHarvestable()
  local stack
  if harvest_bool == true then
    computer.beep(2000)
    for i,v in ipairs(invSlots["harvest"]) do
      stack = ic.getStackInInternalSlot(tonumber(v))
      if stack ~= nil then
        if stack.size < stack.maxSize then -- If there is room
          robot.select(v)
          robot.swingDown()
          break
        end
      else
        robot.select(v)
        robot.swingDown()
        break
      end
    end
    for i,v in ipairs(invSlots["seeds"]) do
      stack = ic.getStackInInternalSlot(tonumber(v))
      if stack ~= nil then
        if stack.size > 0 then -- If there is room
          robot.select(i)
          robot.placeDown()
          break
        end
      else
        robot.select(i)
        robot.placeDown()
        break
      end
    end
  elseif harvest_bool == "no_seed" then
    robot.select(invSlots["seeds"][1])
    computer.beep(500)
    robot.placeDown()
  else
    computer.beep(1000)
  end
end

local function harvestSquare()
  for iz = 1,tonumber(plotsize["z"]) do
    for ix = 1,tonumber(plotsize["x"]) do
      harvestSpot()
      if ix ~= plotsize['x'] then
        robot.forward()
      end
    end
    if iz ~= plotsize['z'] then
      if iz % 2 == 0 then
        robot.turnLeft()
        robot.forward()
        robot.turnLeft()
      else
        robot.turnRight()
        robot.forward()
        robot.turnRight()
      end
    end
  end
  robot.turnRight()
  for ix = 1,tonumber(plotsize["x"]) + 2 do
    robot.forward()
  end
  robot.forward()
  robot.turnRight()
end

local function dropItemsInChest()
  robot.turnAround()
  for i=2,16 do
    robot.select(i)
    ic.dropIntoSlot(sides.front,i)
  end
  robot.turnAround()
end

local function main()
  departFromStart()
  harvestSquare()
  arriveAtStart()
  dropItemsInChest()
end

main()

local component = require("component")
local event = require("event")
local fs = require("filesystem")
local keyboard = require("keyboard")
local shell = require("shell")
local term = require("term")
local text = require("text")
local unicode = require("unicode")
local sides = require("sides")
local colors=require("colors")
local internet = require("internet")
local serial = require("serialization")
local br = component.br_reactor
local bt = component.br_turbine
local gpu = component.gpu

local maxTemp = 5500

local tickCnt = 0
local minCount = 0
local tickEnergy = 0
local minEnergy = 0
local slp = 1
local rodLevel = br.getControlRodLevel(0)

local running = true
local automode = 0
local hours = 0
local mins = 0


term.clear()
term.setCursorBlink(false)
gpu.setResolution(80,25)

-------------------------------------------------------------------------------
function getKey()
  return (select(4, event.pull("key_down")))
end

local function printXY(row, col, s, ...)
  term.setCursor(col, row)
  print(s:format(...))
end

local function gotoXY(row, col)
  term.setCursor(col,row)
end

local function center(row, msg)
  local mLen = string.len(msg)
  w, h = gpu.getResolution()
  term.setCursor((w - mLen)/2,row)
  print(msg)
end

local function centerF(row, msg, ...)
  local mLen = string.len(msg)
  w, h = gpu.getResolution()
  term.setCursor((w - mLen)/2,row)
  print(msg:format(...))
end

local function warning(row, msg)
  local mLen = string.len(msg)
  w, h = gpu.getResolution()
  term.setCursor((w - mLen)/2,row)
  print(msg)
end


local controlKeyCombos = {[keyboard.keys.s]=true,[keyboard.keys.w]=true,
[keyboard.keys.c]=true,[keyboard.keys.x]=true}


local function onKeyDown(opt)
  if opt == keyboard.keys.left then
    br.setActive(false)
  elseif opt == keyboard.keys.right then
    br.setActive(true)
  elseif opt == keyboard.keys.up then
    if (rodLevel > 0) then
      rodLevel = rodLevel - 1
      br.setAllControlRodLevels(rodLevel)
    end
  elseif opt == keyboard.keys.down then
    if (rodLevel < 100) then
      rodLevel = rodLevel + 1
      br.setAllControlRodLevels(rodLevel)
    end
  elseif opt == keyboard.keys.pageDown then
    if (rodLevel < 91) then
      rodLevel = rodLevel + 10
      br.setAllControlRodLevels(rodLevel)
    end
  elseif opt == keyboard.keys.pageUp then
    if (rodLevel > 9) then
      rodLevel = rodLevel - 10
      br.setAllControlRodLevels(rodLevel)
    end
  elseif opt == keyboard.keys.pageDown then
    br.doEjectWaste()
  elseif opt == keyboard.keys.q then
    running = false
  elseif opt == keyboard.keys.m then
    automode = 0
  elseif opt == keyboard.keys.a then
    automode = 1
  end
end


function FormatSeconds(secondsArg)
   local weeks = math.floor(secondsArg / 604800)
   local remainder = secondsArg % 604800
   local days = math.floor(remainder / 86400)
   local remainder = remainder % 86400
   local hours = math.floor(remainder / 3600)
   local remainder = remainder % 3600
   local minutes = math.floor(remainder / 60)
   local seconds = remainder % 60
   return weeks, days, hours, minutes, seconds
end
-------------------------------------------------------------------------------
while running do
  tickCnt = tickCnt + 1
  if tickCnt == 60 then
    mins = mins + 1
    tickCnt = 0
  end
  
  if math.fmod(tickCnt,20) == 0 then 
    br.doEjectWaste()
  end
  
  if mins == 60 then
    hours = hours + 1
    mins = 0
  end
  
  local reactorTemp = br.getCasingTemperature()
  local fuelconsumption_tick = br.getFuelConsumedLastTick()
  local fuelticksremaining = 0
  if (fuelconsumption_tick == 0) then
    fuelticksremaining = 0
  else
    fuelticksremaining = (br.getFuelAmount() / fuelconsumption_tick)
  end  
  local weeks, days, hours, minutes, seconds = FormatSeconds(fuelticksremaining / 20)
  term.setCursor(1,1)
  local xoffset = 1
  if (br.getActive() == false) then
    printXY(xoffset, 5,  "Reactor Status:              %s", "Inactive")
  else
    printXY(xoffset, 5,  "Reactor Status:              %s", "Active  ")
  end
  xoffset = xoffset + 1
  if automode == 1 then
    printXY(xoffset, 5,  "Reactor Mode:                %s", "Automatic")
  else
    printXY(xoffset, 5,  "Reactor Mode:                %s", "Manual   ")
  end
  xoffset = xoffset + 1. printXY(xoffset, 5,  "Reactor Throttle:            %03d%%            ", math.abs(100 - br.getControlRodLevel(1)))
  xoffset = xoffset + 1. printXY(xoffset, 5,  "Reactor Temperature:         %03d              ", br.getCasingTemperature())
  xoffset = xoffset + 1. printXY(xoffset, 5,  "Reactor Fuel Current:        %03d B (%03.2f%%) ", br.getFuelAmount() / 1000, (br.getFuelAmount() / br.getFuelAmountMax() * 100))
  xoffset = xoffset + 1. printXY(xoffset, 5,  "Reactor Consumption:         %03.3f mB/t       ", br.getFuelConsumedLastTick())
  xoffset = xoffset + 1. printXY(xoffset, 5,  "Steam Production:            %04.2f mB/t       ", br.getHotFluidProducedLastTick())
  xoffset = xoffset + 1. printXY(xoffset, 5,  "ETA before empty:            %02d Weeks, %02d days, %02d:%02d:%02d        ", weeks, days, hours, minutes, seconds)
  
--  post_data['total'] = {}
  xoffset = xoffset + 1.
  xoffset = xoffset + 1. if (bt.getInductorEngaged() == false) then printXY(xoffset, 5,  "Turbine Inductor Status:      %s", "Active  ") else printXY(xoffset, 5,  "Turbine Inductor Status:      %s", "Active  ") end
  xoffset = xoffset + 1. printXY(xoffset, 5,  "Rotor Speed:                 %04.2f RPM        ", bt.getRotorSpeed())
  xoffset = xoffset + 1. printXY(xoffset, 5,  "Energy Last Tick:            %06.2f RF/t       ", bt.getEnergyProducedLastTick())
  xoffset = xoffset + 1. printXY(xoffset, 5,  "Energy Stored:               %06d kRF        ", br.getEnergyStored() / 1000)
  xoffset = xoffset + 1.
  xoffset = xoffset + 1.
  centerF(xoffset, "Data updates every second", tickCnt)
  xoffset = xoffset + 1.
  xoffset = xoffset + 1. printXY(xoffset,5, "Left - Turn Reactor Off                      Right - Turn Reactor On")
  xoffset = xoffset + 1. printXY(xoffset,5, "Up arrow - increase Thr. by 1        Down arrow - decrease Thr. by 1")
  xoffset = xoffset + 1. printXY(xoffset,5, "Page Up - increase Thr. by 10        Page Down - decrease Thr. by 10")
  xoffset = xoffset + 1.
  xoffset = xoffset + 1. center(xoffset, "Press Q to quit")
  
  
  local energyperc = br.getEnergyStored() / 10000000 * 100
  if automode == 1 then
    local controlrodsetlevel = 100 - ((100 - energyperc) / 5)
    br.setAllControlRodLevels(controlrodsetlevel)
  end
  term.clearLine()
  print()
  local event, address, arg1, arg2, arg3 = event.pull(1)
  if type(address) == "string" and component.isPrimary(address) then
    if event == "key_down" then
      onKeyDown(arg2)
    end
  end
end
gpu.setResolution(160,50)
term.clear()
term.setCursorBlink(false)
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
local json = require("json")
local post_data = {}
local gpu=component.gpu
local br = component.br_reactor

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
gpu.bind("08dd5944-f989-405b-9094-602ff1c8e0b6")
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
	term.setCursor(1,1)
	local xoffset = 1
  xoffset = xoffset + 1
	xoffset = xoffset + 1
  if (br.getActive() == false) then
    printXY(xoffset, 1,  "Reactor Status:              %s", "Inactive")
  else
    printXY(xoffset, 1,  "Reactor Status:              %s", "Active  ")
  end
  xoffset = xoffset + 1
  if automode == 1 then
    printXY(xoffset, 1,  "Reactor Mode:                %s", "Automatic")
  else
    printXY(xoffset, 1,  "Reactor Mode:                %s", "Manual   ")
  end
  xoffset = xoffset + 1. printXY(xoffset, 1,  "Reactor Throttle:            %03d", math.abs(100 - br.getControlRodLevel(1)))
	xoffset = xoffset + 1. printXY(xoffset, 1,  "Reactor Temperature:         %03d", br.getCasingTemperature())
	xoffset = xoffset + 1. printXY(xoffset, 1,  "Reactor Fuel Current:        %03d B (%03.2f)%   ", br.getFuelAmount() / 1000, (br.getFuelAmount() / br.getFuelAmountMax() * 100))
	xoffset = xoffset + 1. printXY(xoffset, 1,  "Reactor Fuel Maximum:        %03d B", br.getFuelAmountMax() / 1000)
	xoffset = xoffset + 1. printXY(xoffset, 1,  "Reactor Consumption:         %04.2f mB/t", br.getFuelConsumedLastTick())
	xoffset = xoffset + 1. printXY(xoffset, 1, 	"Energy Stored                %03.3f MRF", br.getEnergyStored() / 1000 / 1000)
	xoffset = xoffset + 1. printXY(xoffset, 1, 	"Energy Last Tick             %03d KF", br.getEnergyProducedLastTick() / 1000)
	post_data['total'] = {}
  xoffset = xoffset + 1
	if (br.getActive() == false) then printXY(xoffset, 1,  "Reactor Status:              %s", "Active  ") else printXY(xoffset, 1,  "Reactor Status:              %s", "Active  ") end
	xoffset = xoffset + 1
  xoffset = xoffset + 1.
  xoffset = xoffset + 1.
	centerF(xoffset, "Data updates every second", tickCnt)
  xoffset = xoffset + 1. centerF(xoffset,"Current up time:                       %02d hours %02d min %02d sec", hours, mins, tickCnt)
  xoffset = xoffset + 1. center(xoffset, "Left - Turn Reactor Off                     Right - Turn Reactor On")
  xoffset = xoffset + 1. center(xoffset, "Up arrow - increase Thr. by 1       Down arrow - decrease Thr. by 1")
  xoffset = xoffset + 1. center(xoffset, "Page Up - increase Thr. by 10       Page Down - decrease Thr. by 10")
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
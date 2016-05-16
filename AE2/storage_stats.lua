local component = require("component")
local term = require("term")
local event = require("event")
local keyboard = require("keyboard")
local text = require("text")
local string = require("string")
local mec = component.me_controller
local glass = component.openperipheral_bridge
local totalitems = 0
local ahtotalracks = 15 * 6
local ahdisksize = 65536
local ahtotalcapacity = ahtotalracks * ahdisksize * 10 * 8
local updatefreq = 5

function round(n, idp)
  local mult = 10^(idp or 0)
  return math.floor(n * mult + 0.5) / mult
end

function isint(n)
  return n==math.floor(n)
end

function comma_value(n,idp) -- credit http://richard.warburton.it
  if isint(n) then
    n = tostring(n)
  else
    n = tostring(round(n,idp))
  end
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

local function printXY(row, col, identifier, s)
  term.setCursor(col, row)
  if identifier ~= nil then
    identifier.setText(s)
  else
    --    identifier = glass.addText((col-1)*6,(row-1)*8,s:format(...))
  end
  --print(s:format(...))
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

local function onKeyDown(opt)
  if opt == keyboard.keys.q then
    continue = false
  elseif opt == keyboard.keys.a then
  end
end

local continue = true
local percentageused = 0
local itemspersecond = 0
local itemspersecond_avg5min_total = 0
local itemspersecond_avg5min_i = 1
local itemspersecond_avg5min = 0
local xoffset = 1
local totalitems_last = 0
glass.clear()
local glassText = {}
glassText[0] = {}
glassText[1] = {}
glassText[2] = {}
glassText[3] = {}
glassText[4] = {}
glassText[5] = {}
term.clear()
while continue do
  if glassText[0][0] == nil then glassText[0][0] = glass.addBox(0,0,200,40,0xFFFFFF, 0.3) end if glassText[0][0].getId() == nil then glassText[0][0] = glass.addBox(0,0,200,40,0xFFFFFF, 0.2) end
  if glassText[1][1] == nil then glassText[1][1] = glass.addText(5,5,"") glassText[1][1].setScale(0.5) end if glassText[1][1].getId() == nil then glassText[1][1] = glass.addText(0,5,"") glassText[1][1].setScale(0.5) end
  if glassText[2][1] == nil then glassText[2][1] = glass.addText(5,11,"") glassText[2][1].setScale(0.5) end if glassText[2][1].getId() == nil then glassText[2][1] = glass.addText(0,11,"") glassText[2][1].setScale(0.5) end
  if glassText[3][1] == nil then glassText[3][1] = glass.addText(5,17,"") glassText[3][1].setScale(0.5) end if glassText[3][1].getId() == nil then glassText[3][1] = glass.addText(0,17,"") glassText[3][1].setScale(0.5) end
  if glassText[4][1] == nil then glassText[4][1] = glass.addText(5,23,"") glassText[4][1].setScale(0.5) end if glassText[4][1].getId() == nil then glassText[4][1] = glass.addText(0,23,"") glassText[4][1].setScale(0.5) end
  if glassText[5][1] == nil then glassText[5][1] = glass.addText(5,29,"") glassText[5][1].setScale(0.5) end if glassText[5][1].getId() == nil then glassText[5][1] = glass.addText(0,29,"") glassText[5][1].setScale(0.5) end
  
  if glassText[1][2] == nil then glassText[1][2] = glass.addText(150,5,"") glassText[1][2].setScale(0.5) end if glassText[1][2].getId() == nil then glassText[1][2] = glass.addText(150,5,"") glassText[1][2].setScale(0.5) end
  if glassText[2][2] == nil then glassText[2][2] = glass.addText(150,11,"") glassText[2][2].setScale(0.5) end if glassText[2][2].getId() == nil then glassText[2][2] = glass.addText(150,11,"") glassText[2][2].setScale(0.5) end
  if glassText[3][2] == nil then glassText[3][2] = glass.addText(150,17,"") glassText[3][2].setScale(0.5) end if glassText[3][2].getId() == nil then glassText[3][2] = glass.addText(150,17,"") glassText[3][2].setScale(0.5) end
  if glassText[4][2] == nil then glassText[4][2] = glass.addText(150,23,"") glassText[4][2].setScale(0.5) end if glassText[4][2].getId() == nil then glassText[4][2] = glass.addText(150,23,"") glassText[4][2].setScale(0.5) end
  if glassText[5][2] == nil then glassText[5][2] = glass.addText(150,29,"") glassText[5][2].setScale(0.5) end if glassText[5][2].getId() == nil then glassText[5][2] = glass.addText(150,29,"") glassText[5][2].setScale(0.5) end
  --glass.clear();
  itemList = mec.getItemsInNetwork()
  for i=1,#itemList do
    totalitems = totalitems + itemList[i].size
  end
  if itemspersecond_avg5min_i > 1 then
    itemspersecond = (totalitems - totalitems_last) / updatefreq
    itemspersecond_avg5min_total = itemspersecond_avg5min_total + itemspersecond
    if itemspersecond_avg5min_i > (300 / updatefreq) then
      itemspersecond_avg5min_total = itemspersecond_avg5min_total - itemspersecond_avg5min + itemspersecond
      itemspersecond_avg5min_i = itemspersecond_avg5min_i - updatefreq
    end
    itemspersecond_avg5min = itemspersecond_avg5min_total / itemspersecond_avg5min_i
    totalitems_last = totalitems
    xoffset = 1
    percentageused = (totalitems / ahtotalcapacity) * 100
    xoffset = xoffset + 1 printXY(xoffset, 1, glassText[1][1],  "Number of different items in the AH")   printXY(xoffset,40, glassText[1][2], comma_value((#itemList),0))
    xoffset = xoffset + 1 printXY(xoffset, 1, glassText[2][1],  "Total number of items in the AH")       printXY(xoffset,40, glassText[2][2], comma_value((totalitems),0))
    xoffset = xoffset + 1 printXY(xoffset, 1, glassText[3][1],  "Percentage used of AH's capacity")      printXY(xoffset,40, glassText[3][2], comma_value((percentageused),2))
    xoffset = xoffset + 1 printXY(xoffset, 1, glassText[4][1],  "Number of items per second")            printXY(xoffset,40, glassText[4][2], comma_value((itemspersecond),1))
    xoffset = xoffset + 1 printXY(xoffset, 1, glassText[5][1],  "Number of items per second avg(5min)")  printXY(xoffset,40, glassText[5][2], comma_value((itemspersecond_avg5min),1))
    local event, address, arg1, arg2, arg3 = event.pull(1)
    if type(address) == "string" and component.isPrimary(address) then
      if event == "key_down" then
        onKeyDown(arg2)
      end
    end
    
    totalitems = 0
    glass.sync()
    os.sleep(updatefreq)
  else
    totalitems_last = totalitems
  end
  itemspersecond_avg5min_i = itemspersecond_avg5min_i + updatefreq
end


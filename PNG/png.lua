--[[
  Advanced PNG ToShow
  (PNG decoding lib by TehSomeLuigi, 2014)
  
  PNG images Viewer by Totoro, 2015
]]--

local args = {...}

local event = require("event")
local term = require("term")
local fs = require("filesystem")
local shell = require("shell")
local computer = require('computer')
local bit = require("bit32")
local PNGImage = require("libPNGimage")
local com = require("component")
local gpu = com.gpu

local out = io.stdout
local err = io.stderr

local color = {}
color.fore = 0xFFFFFF
color.back = 0x000000
local refreshtime = 300

if not args[1] then
  print("Enter filename of PNG Image:")
  io.stdout:write(": ")
  args[1] = io.read()
elseif args[1] == "-h" or args[1] == "--help" or args[1] == "-?" then
  print("Usage: toshow <filename>")
end

args[1] = shell.resolve(args[1], "png")

if not fs.exists(args[1]) then
  err:write("[ToShow Error]\n")
  err:write("The file '" .. tostring(args[1]) .. "' does not exist.\n")
  return
end

-- now attempt to load the PNG image
-- run in protected call to handle potential errors

local success, pngi = pcall(PNGImage.newFromFile, args[1])

if not success then
  err:write("[ToShow: PNG Loading Error]\n")
  err:write("While attempting to load '" .. tostring(args[1]) .. "' as PNG, libPNGImage erred:\n")
  err:write(pngi)
  return
end

local imgW, imgH = pngi:getSize()
local maxresW, maxresH = gpu.maxResolution()

if imgW > maxresW then
  err:write("[ToShow: PNG Display Error]\n")
  err:write("A width resolution of at least " .. imgW .. " is required, only " .. maxresW .. " available.\n")
  return
end

if imgH > maxresH*2 then
  err:write("[ToShow: PNG Display Error]\n")
  err:write("A height resolution of at least " .. imgH .. " is required, only " .. maxresH .. " available.\n")
  return
end

-- draw loaded image

local oldResW, oldResH = gpu.getResolution() -- store for later
local oldBackN, oldBackB = gpu.getBackground()
local oldForeN, oldForeB = gpu.getForeground()

local block = '▀'
local H = math.ceil(imgH/2)

gpu.setBackground(color.back, false)
gpu.setResolution(imgW, H)

function rgb2hex(r,g,b)
  return r*65536+g*256+b
end

function draw()
  for x = 0, imgW-1 do
    local dy = 1
    for y = 0, imgH-1, 2 do
      -- upper half
      local r, g, b, a = pngi:getPixel(x, y)
      if a > 0 then
        gpu.setForeground(bit.bor(bit.lshift(r, 16), bit.bor(bit.lshift(g, 8), b)))
      else
        gpu.setForeground(color.back)
      end
      -- lower half
      if (y+1) < imgH then
        r, g, b, a = pngi:getPixel(x, y+1)
        if a > 0 then
          gpu.setBackground(bit.bor(bit.lshift(r, 16), bit.bor(bit.lshift(g, 8), b)))
        else
          gpu.setBackground(color.back)
        end
      else
        gpu.setBackground(color.back)
      end
      -- output
      gpu.set(x+1, dy, block)
      dy = dy + 1
    end
  end
end

draw()

time = computer.uptime()
while true do
  name, add, x, y = event.pull(10)
  if name == 'key_down' then break 
  elseif name == "touch" then
    --gpu.set(x, y, "*")
  end
  if computer.uptime() - time > 60 then
    gpu.set(1,1,'_')
    gpu.set(1,1,' ')
    time = computer.uptime()
  end
end

-- restore old resolution and colors
gpu.setForeground(oldForeN, oldForeB)
gpu.setBackground(oldBackN, oldBackB)
term.clear()
gpu.setResolution(oldResW, oldResH)
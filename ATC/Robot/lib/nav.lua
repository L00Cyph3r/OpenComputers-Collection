local component = require("component")
local navigation = component.navigation
local serial = require("serialization")
local fs = require("filesystem")
local shell = require("shell")
local component = require("component")
local str = require("string")

nav = {}
-- Searches for waypoints in the vicinity of 500 meters
-- if no waypoint is found, it's doomed
function nav.getWaypoints()
  
end

-- Returns a string with current compass heading based on the internal
-- upgrade
function nav.getFacing()
  local facing_int = navigation.getFacing()
  if facing_int == 2 then
    return 'north'
  elseif facing_int == 3 then
    return 'south'
  elseif facing_int == 4 then
    return 'west'
  elseif facing_int == 5 then
    return 'east'
  end
end
-- We use the normal x,y,z-system, not the minecraft version
-- x=E/W, y=N/S, Z=up/down
function nav.getPos()
  local wplist = component.navigation.findWaypoints(500)
  if #wplist > 0 then
    local wp = wplist[1]
    local label,x,y,z = str.match(wp.label,"([^,]+),([^,]+),([^,]+),([^,]+)")
    ret = {}
    ret['label'] = label
    ret['x'] = x - wp.position[1]
    ret['y'] = y - wp.position[3]
    ret['z'] = z - wp.position[2]
    return ret
  else
    return false
  end
end

function nav.calcDistance(x,y,z)
  local curpos = nav.getPos()
  local dist_x = math.abs(tonumber(x) - tonumber(curpos.x))
  local dist_y = math.abs(tonumber(y) - tonumber(curpos.y))
  local dist_z = math.abs(tonumber(z) - tonumber(curpos.z))
  local total_dist = dist_x + dist_y + dist_z
  return total_dist
end
return nav